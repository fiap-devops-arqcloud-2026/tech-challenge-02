# ☁️ Guia de Deploy na AWS — ToggleMaster

> ⚠️ **ATENÇÃO — ESTE GUIA ESTÁ PARCIALMENTE DESATUALIZADO.**
> Ele descreve o plano inicial: **3 instâncias RDS** e região **us-east-1**. A arquitetura mudou para:
> **2 RDS** (auth, flags) + **targeting como pod no EKS** + **ElastiCache** (Redis), tudo em **us-east-2 (Ohio)**.
> A **fonte da verdade atual** é a pasta `00_COLAB_IA/` (DOSSIE / PENDENCIAS / DECISOES).
> A atualização completa deste guia é a pendência **P-006**.

> **Para quem é este guia?** Para qualquer pessoa que queira colocar o ToggleMaster rodando na AWS, mesmo sem experiência prévia com cloud.
>
> **Tempo estimado:** 2 a 3 horas para criar toda a infraestrutura.
>
> **Custo estimado:** R$ 15–25 se você derrubar tudo logo após gravar o vídeo.

---

## 📑 Índice

1. [Ferramentas necessárias](#1-ferramentas-necessárias)
2. [Criar usuário IAM e credenciais](#2-criar-usuário-iam-e-credenciais)
3. [Configurar a AWS CLI](#3-configurar-a-aws-cli)
4. [Criar repositórios no ECR e enviar as imagens](#4-criar-repositórios-no-ecr-e-enviar-as-imagens)
5. [Criar os bancos de dados RDS (PostgreSQL)](#5-criar-os-bancos-de-dados-rds-postgresql)
6. [Criar o cache Redis (ElastiCache)](#6-criar-o-cache-redis-elasticache)
7. [Criar a tabela DynamoDB](#7-criar-a-tabela-dynamodb)
8. [Criar a fila SQS](#8-criar-a-fila-sqs)
9. [Criar o cluster Kubernetes (EKS)](#9-criar-o-cluster-kubernetes-eks)
10. [Configurar o cluster (Metrics Server + Nginx)](#10-configurar-o-cluster-metrics-server--nginx)
11. [Preencher os manifests e fazer o deploy](#11-preencher-os-manifests-e-fazer-o-deploy)
12. [Criar a chave de API de produção](#12-criar-a-chave-de-api-de-produção)
13. [Verificar que tudo está funcionando](#13-verificar-que-tudo-está-funcionando)
14. [⚠️ Derrubar tudo após o vídeo](#️-derrubar-tudo-após-o-vídeo)

---

## 1. Ferramentas necessárias

Antes de começar, instale estas ferramentas no seu computador:

### AWS CLI — A "linha de comando" da AWS
```
https://aws.amazon.com/cli/
```
Clique em **"Download AWS CLI"**, instale e depois feche e abra o terminal.

### kubectl — Controla o Kubernetes pelo terminal
```
https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```
Baixe o arquivo `kubectl.exe` e coloque em `C:\Windows\System32\`.

### eksctl — Cria o cluster EKS com um comando
```
https://eksctl.io/installation/
```
Siga as instruções para Windows.

### Helm — Instala componentes no Kubernetes
Execute no terminal:
```powershell
winget install Helm.Helm
```

### Verificar instalações
Depois de instalar tudo, abra um terminal **novo** e execute:
```powershell
aws --version        # deve mostrar: aws-cli/2.x.x
kubectl version      # deve mostrar a versão
eksctl version       # deve mostrar: 0.x.x
helm version         # deve mostrar: version.BuildInfo{...}
```

---

## 2. Criar usuário IAM e credenciais

> **O que é IAM?** É o "controle de acesso" da AWS. Um usuário IAM é como um crachá de funcionário — define o que cada pessoa/programa pode fazer na AWS.

### No Console AWS:

1. Acesse **console.aws.amazon.com** e faça login
2. Na barra de busca do topo, digite **IAM** e clique no serviço
3. No menu esquerdo, clique em **Usuários**
4. Clique em **Criar usuário**

### Configurações do usuário:

| Campo | Valor |
|---|---|
| Nome do usuário | `togglemaster-deploy` |
| Acesso ao Console AWS | **Não** (deixe desmarcado) |

5. Clique em **Próximo**
6. Em **Definir permissões**, escolha **"Anexar políticas diretamente"**
7. Marque as seguintes políticas (use a busca):
   - `AmazonEKSFullAccess`
   - `AmazonEC2FullAccess`
   - `AmazonRDSFullAccess`
   - `AmazonElastiCacheFullAccess`
   - `AmazonDynamoDBFullAccess`
   - `AmazonSQSFullAccess`
   - `AmazonECRFullAccess`
   - `IAMFullAccess`

8. Clique em **Próximo** → **Criar usuário**

### Criar a chave de acesso:

9. Clique no usuário `togglemaster-deploy` que você criou
10. Clique na aba **Credenciais de segurança**
11. Desça até **Chaves de acesso** → clique em **Criar chave de acesso**
12. Escolha **Interface de linha de comando (CLI)**
13. Marque a confirmação e clique em **Próximo** → **Criar chave de acesso**

> ⚠️ **IMPORTANTE:** Na tela seguinte você verá o `Access Key ID` e o `Secret Access Key`.
> **Copie os dois valores agora** — você não poderá ver a Secret Key novamente!

Guarde os dois valores no seu `.env`:
```env
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE      # cole o seu valor aqui
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI...      # cole o seu valor aqui
```

---

## 3. Configurar a AWS CLI

Com a AWS CLI instalada e as credenciais em mãos, execute no terminal:

```powershell
aws configure
```

Preencha as perguntas:
```
AWS Access Key ID:     → cole seu Access Key ID
AWS Secret Access Key: → cole seu Secret Access Key
Default region name:   → us-east-1
Default output format: → json
```

### Verificar se funcionou:
```powershell
aws sts get-caller-identity
```
Deve retornar um JSON com `"Account"`, `"UserId"` e `"Arn"`. Se aparecer, está configurado. ✅

> 📝 **Anote seu Account ID** (o número de 12 dígitos no campo `"Account"`).
> Você vai precisar dele para construir as URLs do ECR.
> Salve no `.env`: `AWS_ACCOUNT_ID=123456789012`

---

## 4. Criar repositórios no ECR e enviar as imagens

> **O que é ECR?** É o "Google Drive de imagens Docker" da Amazon — onde suas imagens ficam guardadas para o Kubernetes baixar.

### 4.1 Criar os 5 repositórios

Execute cada comando (substitua `us-east-1` pela sua região se for diferente):

```powershell
aws ecr create-repository --repository-name auth-service       --region us-east-1
aws ecr create-repository --repository-name flag-service       --region us-east-1
aws ecr create-repository --repository-name targeting-service  --region us-east-1
aws ecr create-repository --repository-name evaluation-service --region us-east-1
aws ecr create-repository --repository-name analytics-service  --region us-east-1
```

### 4.2 Autenticar o Docker com o ECR

```powershell
# Substitua 123456789012 pelo seu Account ID e us-east-1 pela sua região
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

Deve aparecer: `Login Succeeded` ✅

### 4.3 Construir as imagens (se ainda não fez)

Na pasta raiz do projeto:
```powershell
docker compose build
```

### 4.4 Taguear as imagens com o endereço do ECR

```powershell
# Substitua 123456789012 pelo seu Account ID

docker tag tech-challenge-02-auth-service:latest       123456789012.dkr.ecr.us-east-1.amazonaws.com/auth-service:latest
docker tag tech-challenge-02-flag-service:latest       123456789012.dkr.ecr.us-east-1.amazonaws.com/flag-service:latest
docker tag tech-challenge-02-targeting-service:latest  123456789012.dkr.ecr.us-east-1.amazonaws.com/targeting-service:latest
docker tag tech-challenge-02-evaluation-service:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/evaluation-service:latest
docker tag tech-challenge-02-analytics-service:latest  123456789012.dkr.ecr.us-east-1.amazonaws.com/analytics-service:latest
```

### 4.5 Enviar as imagens para o ECR

```powershell
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/auth-service:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/flag-service:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/targeting-service:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/evaluation-service:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/analytics-service:latest
```

> O upload pode demorar alguns minutos dependendo da sua internet.

### 4.6 Atualizar os Deployments com as URLs do ECR

Abra cada arquivo abaixo e substitua o campo `image:` pela URL real:

| Arquivo | Valor do campo `image:` |
|---|---|
| `infra/k8s/auth-service/deployment.yaml` | `123456789012.dkr.ecr.us-east-1.amazonaws.com/auth-service:latest` |
| `infra/k8s/flag-service/deployment.yaml` | `123456789012.dkr.ecr.us-east-1.amazonaws.com/flag-service:latest` |
| `infra/k8s/targeting-service/deployment.yaml` | `123456789012.dkr.ecr.us-east-1.amazonaws.com/targeting-service:latest` |
| `infra/k8s/evaluation-service/deployment.yaml` | `123456789012.dkr.ecr.us-east-1.amazonaws.com/evaluation-service:latest` |
| `infra/k8s/analytics-service/deployment.yaml` | `123456789012.dkr.ecr.us-east-1.amazonaws.com/analytics-service:latest` |

---

## 5. Criar os bancos de dados RDS (PostgreSQL)

> **O que é RDS?** É o "banco de dados gerenciado" da AWS — você não precisa instalar ou manter o PostgreSQL. A Amazon cuida de tudo.

> ⚠️ **Dica de custo:** O Free Tier cobre 750h/mês de `db.t3.micro`. Crie os 3 bancos e deixe rodando apenas durante o período do desafio.

Você vai criar **3 instâncias RDS**, uma para cada serviço. O processo é o mesmo para as 3 — repita os passos abaixo mudando apenas o nome.

### Para cada banco de dados:

1. Na busca do console AWS, digite **RDS** e clique no serviço
2. Clique em **Criar banco de dados**
3. Escolha **Criação padrão**
4. Em **Mecanismo**, selecione **PostgreSQL**
5. Em **Modelos**, selecione **Nível gratuito** (Free Tier)

### Configurações (repita 3 vezes com os nomes abaixo):

| Campo | Banco 1 (auth) | Banco 2 (flags) | Banco 3 (targeting) |
|---|---|---|---|
| Identificador da instância | `togglemaster-auth` | `togglemaster-flags` | `togglemaster-targeting` |
| Nome do banco inicial | `auth_db` | `flags_db` | `targeting_db` |
| Nome de usuário | `toggle` | `toggle` | `toggle` |
| Senha | Escolha uma senha forte | Mesma senha | Mesma senha |
| Classe da instância | `db.t3.micro` | `db.t3.micro` | `db.t3.micro` |
| Armazenamento | 20 GB (mínimo) | 20 GB | 20 GB |
| Acesso público | **Sim** (para testes) | **Sim** | **Sim** |

6. Em **Grupos de segurança VPC**, anote qual VPC e security group foram usados (você precisará do mesmo para o EKS)
7. Clique em **Criar banco de dados**
8. Aguarde o status mudar para **Disponível** (pode demorar 5–10 min)

### Anotar os endpoints:

Após criar cada banco, clique nele e copie o **Endpoint**. Será algo como:
```
togglemaster-auth.abc123xyz.us-east-1.rds.amazonaws.com
```

Salve no seu `.env`:
```env
AUTH_DATABASE_URL=postgres://toggle:SuaSenha@togglemaster-auth.abc123xyz.us-east-1.rds.amazonaws.com:5432/auth_db
FLAGS_DATABASE_URL=postgres://toggle:SuaSenha@togglemaster-flags.abc123xyz.us-east-1.rds.amazonaws.com:5432/flags_db
TARGETING_DATABASE_URL=postgres://toggle:SuaSenha@togglemaster-targeting.abc123xyz.us-east-1.rds.amazonaws.com:5432/targeting_db
```

---

## 6. Criar o cache Redis (ElastiCache)

> **O que é ElastiCache?** É o Redis gerenciado da Amazon — o evaluation-service usa para guardar respostas em memória por 30 segundos, tornando as avaliações muito mais rápidas.

1. Na busca do console, digite **ElastiCache** e clique no serviço
2. Clique em **Criar cluster**
3. Escolha **Cache de Redis (modo clique)**
4. Escolha **Design your own cache** → **Cluster cache**

### Configurações:

| Campo | Valor |
|---|---|
| Nome do cluster | `togglemaster-redis` |
| Localização | AWS Cloud |
| Mecanismo | Redis OSS |
| Versão | 7.x (mais recente) |
| Tipo de nó | `cache.t3.micro` |
| Número de réplicas | 0 (para economizar — é para teste) |

5. Clique em **Próximo** → **Próximo** → **Criar**
6. Aguarde o status **Disponível**
7. Clique no cluster e copie o **Endpoint primário**

Salve no `.env`:
```env
REDIS_URL=redis://togglemaster-redis.abc123.cache.amazonaws.com:6379
```

---

## 7. Criar a tabela DynamoDB

> **O que é DynamoDB?** É o banco NoSQL da Amazon — o analytics-service salva aqui cada evento de avaliação de flag. É completamente gratuito no Free Tier.

1. Na busca do console, digite **DynamoDB** e clique no serviço
2. Clique em **Criar tabela**

### Configurações:

| Campo | Valor |
|---|---|
| Nome da tabela | `ToggleMasterAnalytics` |
| Chave de partição | `event_id` |
| Tipo da chave | `String` |
| Configurações da tabela | Configurações padrão |

3. Clique em **Criar tabela**
4. Pronto — o DynamoDB não tem endpoint para anotar. O boto3 usa automaticamente a região configurada.

Confirme no `.env`:
```env
AWS_DYNAMODB_TABLE=ToggleMasterAnalytics
AWS_REGION=us-east-1
```

---

## 8. Criar a fila SQS

> **O que é SQS?** É uma fila de mensagens — o evaluation-service coloca eventos nela e o analytics-service consome. É como uma caixa de entrada compartilhada entre os dois serviços.

1. Na busca do console, digite **SQS** e clique no serviço
2. Clique em **Criar fila**

### Configurações:

| Campo | Valor |
|---|---|
| Tipo | **Standard** (não escolha FIFO) |
| Nome | `togglemaster-events` |
| Período de retenção de mensagens | 4 dias (padrão) |
| Todas as outras configurações | Padrão |

3. Clique em **Criar fila**
4. Copie a **URL** da fila — será algo como:
```
https://sqs.us-east-1.amazonaws.com/123456789012/togglemaster-events
```

Salve no `.env`:
```env
AWS_SQS_URL=https://sqs.us-east-1.amazonaws.com/123456789012/togglemaster-events
```

---

## 9. Criar o cluster Kubernetes (EKS)

> **O que é EKS?** É o Kubernetes gerenciado da Amazon — você não precisa configurar o Kubernetes manualmente. A Amazon mantém o "cérebro" do cluster.

> ⚠️ **Atenção ao custo:** O cluster EKS cobra **~R$0,55/hora** pelo control plane, independente de estar sendo usado. Crie **somente quando for fazer o deploy e gravar o vídeo**.

### Criar o cluster com eksctl (método recomendado):

```powershell
eksctl create cluster `
  --name togglemaster-cluster `
  --region us-east-1 `
  --nodegroup-name workers `
  --node-type t3.small `
  --nodes 2 `
  --nodes-min 1 `
  --nodes-max 4 `
  --managed
```

> Este comando cria o cluster E os servidores (nós) automaticamente. Demora cerca de **15–20 minutos**.

Quando terminar, você verá: `EKS cluster "togglemaster-cluster" in "us-east-1" region is ready`

### Conectar o kubectl ao cluster:

```powershell
aws eks update-kubeconfig --region us-east-1 --name togglemaster-cluster
```

### Verificar conexão:

```powershell
kubectl get nodes
```

Deve mostrar 2 servidores com status `Ready`. ✅

---

## 10. Configurar o cluster (Metrics Server + Nginx)

### 10.1 Instalar o Metrics Server

> Obrigatório para o HPA (escalabilidade automática) funcionar.

```powershell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Verificar (aguarde 1 minuto):
```powershell
kubectl get deployment metrics-server -n kube-system
```
Deve aparecer `READY 1/1`. ✅

### 10.2 Instalar o Nginx Ingress Controller

> É a "porta de entrada" pública do cluster que vai criar o Load Balancer na AWS.

```powershell
# Adicionar o repositório do Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Instalar o Nginx Ingress
helm install ingress-nginx ingress-nginx/ingress-nginx `
  --namespace ingress-nginx `
  --create-namespace
```

Verificar (aguarde 2–3 minutos para o Load Balancer ser criado):
```powershell
kubectl get service ingress-nginx-controller -n ingress-nginx
```

Aguarde até aparecer um endereço no campo `EXTERNAL-IP`. Será algo como:
```
abc123.us-east-1.elb.amazonaws.com
```

> 📝 **Anote este endereço** — ele é a URL pública do seu sistema!

---

## 11. Preencher os manifests e fazer o deploy

### 11.1 Gerar os valores Base64 para os Secrets

Os Kubernetes Secrets precisam dos valores em Base64. Execute no PowerShell:

```powershell
# Como gerar Base64 no PowerShell:
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("seu-valor-aqui"))
```

Gere Base64 para cada valor e preencha nos arquivos `secret.yaml`:

| Arquivo | Campo | Valor para converter |
|---|---|---|
| `auth-service/secret.yaml` | `DATABASE_URL` | `postgres://toggle:SENHA@ENDPOINT_AUTH:5432/auth_db` |
| `auth-service/secret.yaml` | `MASTER_KEY` | Sua master key de produção |
| `flag-service/secret.yaml` | `DATABASE_URL` | `postgres://toggle:SENHA@ENDPOINT_FLAGS:5432/flags_db` |
| `targeting-service/secret.yaml` | `DATABASE_URL` | `postgres://toggle:SENHA@ENDPOINT_TARGETING:5432/targeting_db` |
| `evaluation-service/secret.yaml` | `SERVICE_API_KEY` | Será criado no passo 12 |
| `evaluation-service/secret.yaml` | `AWS_SQS_URL` | URL da fila SQS |
| `evaluation-service/secret.yaml` | `AWS_ACCESS_KEY_ID` | Seu Access Key ID |
| `evaluation-service/secret.yaml` | `AWS_SECRET_ACCESS_KEY` | Sua Secret Access Key |
| `analytics-service/secret.yaml` | `AWS_SQS_URL` | URL da fila SQS |
| `analytics-service/secret.yaml` | `AWS_ACCESS_KEY_ID` | Seu Access Key ID |
| `analytics-service/secret.yaml` | `AWS_SECRET_ACCESS_KEY` | Sua Secret Access Key |

### 11.2 Atualizar os ConfigMaps

Abra e preencha os valores reais nos arquivos `configmap.yaml`:

| Arquivo | Campo | Valor |
|---|---|---|
| `evaluation-service/configmap.yaml` | `REDIS_URL` | `redis://SEU_ENDPOINT_ELASTICACHE:6379` |
| `analytics-service/configmap.yaml` | `AWS_REGION` | `us-east-1` |

### 11.3 Aplicar todos os manifests

Execute na ordem:
```powershell
# 1. Criar o namespace
kubectl apply -f infra/k8s/00-namespaces.yaml

# 2. Aplicar os recursos de cada serviço
kubectl apply -f infra/k8s/auth-service/
kubectl apply -f infra/k8s/flag-service/
kubectl apply -f infra/k8s/targeting-service/
kubectl apply -f infra/k8s/evaluation-service/
kubectl apply -f infra/k8s/analytics-service/

# 3. Aplicar o Ingress
kubectl apply -f infra/k8s/ingress.yaml
```

### 11.4 Verificar os pods

```powershell
# Ver todos os pods do projeto
kubectl get pods -n togglemaster

# Acompanhar em tempo real
kubectl get pods -n togglemaster -w
```

Aguarde todos ficarem com status `Running`. Pode levar 1–2 minutos.

```powershell
# Se algum pod não subir, veja o log de erro:
kubectl logs -n togglemaster deployment/auth-service
```

---

## 12. Criar a chave de API de produção

O banco de dados RDS começa vazio — a chave de API que foi criada localmente não existe em produção. Você precisa criar uma nova.

### Descobrir a URL pública do Load Balancer:
```powershell
kubectl get ingress -n togglemaster
```
Anote o valor em `ADDRESS` — é o seu endereço público.

### Criar a chave de API para o evaluation-service:
```powershell
# Substitua SEU_LOAD_BALANCER pelo endereço do Ingress
# Substitua SUA_MASTER_KEY pela master key que você configurou no secret

curl.exe -X POST http://SEU_LOAD_BALANCER/admin/keys `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer SUA_MASTER_KEY" `
  -d '{\"name\": \"evaluation-service-prod\"}'
```

Copie o valor de `"key"` retornado e:
1. Converta para Base64
2. Atualize o campo `SERVICE_API_KEY` em `infra/k8s/evaluation-service/secret.yaml`
3. Reaplique o secret:

```powershell
kubectl apply -f infra/k8s/evaluation-service/secret.yaml
kubectl rollout restart deployment/evaluation-service -n togglemaster
```

---

## 13. Verificar que tudo está funcionando

### Health checks de todos os serviços:
```powershell
# Substitua SEU_LOAD_BALANCER pelo endereço do Ingress
curl.exe http://SEU_LOAD_BALANCER/validate
```

### Criar uma flag de teste:
```powershell
# 1. Criar chave para testes manuais
curl.exe -X POST http://SEU_LOAD_BALANCER/admin/keys `
  -H "Authorization: Bearer SUA_MASTER_KEY" `
  -H "Content-Type: application/json" `
  -d '{\"name\": \"teste-manual\"}'

# 2. Criar flag (substitua SUA_CHAVE_API pela chave criada acima)
curl.exe -X POST http://SEU_LOAD_BALANCER/flags `
  -H "Authorization: Bearer SUA_CHAVE_API" `
  -H "Content-Type: application/json" `
  -d '{\"name\": \"feature-producao\", \"is_enabled\": true}'

# 3. Criar regra (50% dos usuários)
curl.exe -X POST http://SEU_LOAD_BALANCER/rules `
  -H "Authorization: Bearer SUA_CHAVE_API" `
  -H "Content-Type: application/json" `
  -d '{\"flag_name\": \"feature-producao\", \"is_enabled\": true, \"rules\": {\"type\": \"PERCENTAGE\", \"value\": 50}}'

# 4. Avaliar (deve retornar true ou false)
curl.exe "http://SEU_LOAD_BALANCER/evaluate?user_id=usuario-teste&flag_name=feature-producao"
```

### Verificar os HPAs:
```powershell
kubectl get hpa -n togglemaster
```

### Verificar o Ingress:
```powershell
kubectl get ingress -n togglemaster
```

---

## ⚠️ Derrubar tudo após o vídeo

Para não gastar dinheiro com infraestrutura parada, derrube tudo depois de gravar o vídeo:

```powershell
# 1. Deletar o cluster EKS (e todos os recursos dentro dele)
eksctl delete cluster --name togglemaster-cluster --region us-east-1

# 2. Deletar os bancos RDS (pelo console AWS ou com AWS CLI)
aws rds delete-db-instance --db-instance-identifier togglemaster-auth      --skip-final-snapshot --region us-east-1
aws rds delete-db-instance --db-instance-identifier togglemaster-flags     --skip-final-snapshot --region us-east-1
aws rds delete-db-instance --db-instance-identifier togglemaster-targeting --skip-final-snapshot --region us-east-1

# 3. Deletar o ElastiCache
aws elasticache delete-replication-group --replication-group-id togglemaster-redis --region us-east-1

# 4. Deletar a fila SQS (substitua pelo ARN da sua fila)
aws sqs delete-queue --queue-url https://sqs.us-east-1.amazonaws.com/123456789012/togglemaster-events

# 5. As imagens no ECR e a tabela DynamoDB ficam no Free Tier — pode deixar
```

> 💡 **Dica:** O comando `eksctl delete cluster` já cuida do Load Balancer e dos nodes EC2 automaticamente.

---

## 📝 Tabela de valores para anotar

Guarde estes valores conforme for criando cada recurso:

| Recurso | Valor a anotar | Campo no .env |
|---|---|---|
| IAM Access Key | `AKIAXXXXXXXX` | `AWS_ACCESS_KEY_ID` |
| IAM Secret Key | `wJalrXXXXXX` | `AWS_SECRET_ACCESS_KEY` |
| Account ID | `123456789012` | `AWS_ACCOUNT_ID` |
| RDS auth endpoint | `togglemaster-auth.xxx.rds.amazonaws.com` | `AUTH_DATABASE_URL` |
| RDS flags endpoint | `togglemaster-flags.xxx.rds.amazonaws.com` | `FLAGS_DATABASE_URL` |
| RDS targeting endpoint | `togglemaster-targeting.xxx.rds.amazonaws.com` | `TARGETING_DATABASE_URL` |
| ElastiCache endpoint | `togglemaster-redis.xxx.cache.amazonaws.com` | `REDIS_URL` |
| SQS URL | `https://sqs.us-east-1.amazonaws.com/xxx/togglemaster-events` | `AWS_SQS_URL` |
| Load Balancer DNS | `abc123.us-east-1.elb.amazonaws.com` | URL pública do sistema |
