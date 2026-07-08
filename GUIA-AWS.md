# ☁️ Guia de Deploy na AWS — ToggleMaster

> ✅ **GUIA ATUALIZADO EM 2026-07-06** para refletir o deploy que foi **realmente executado**:
> região **us-east-2 (Ohio)** · **2 RDS** (auth, flags) + **targeting como pod no EKS** (limite de
> 2 RDS do plano gratuito) · ElastiCache, SQS e DynamoDB · cluster criado pelo **console**
> (não eksctl) com nós **c7i-flex.large** (o plano gratuito bloqueia a t3.medium).
> A arquitetura completa com diagrama está em [`docs/ARQUITETURA.md`](./docs/ARQUITETURA.md);
> o histórico de decisões, em `00_COLAB_IA/DECISOES.md`.

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
Default region name:   → us-east-2
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

Execute cada comando (substitua `us-east-2` pela sua região se for diferente):

```powershell
aws ecr create-repository --repository-name auth-service       --region us-east-2
aws ecr create-repository --repository-name flag-service       --region us-east-2
aws ecr create-repository --repository-name targeting-service  --region us-east-2
aws ecr create-repository --repository-name evaluation-service --region us-east-2
aws ecr create-repository --repository-name analytics-service  --region us-east-2
```

### 4.2 Autenticar o Docker com o ECR

```powershell
# Substitua 123456789012 pelo seu Account ID e us-east-2 pela sua região
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-2.amazonaws.com
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

docker tag tech-challenge-02-auth-service:latest       123456789012.dkr.ecr.us-east-2.amazonaws.com/auth-service:latest
docker tag tech-challenge-02-flag-service:latest       123456789012.dkr.ecr.us-east-2.amazonaws.com/flag-service:latest
docker tag tech-challenge-02-targeting-service:latest  123456789012.dkr.ecr.us-east-2.amazonaws.com/targeting-service:latest
docker tag tech-challenge-02-evaluation-service:latest 123456789012.dkr.ecr.us-east-2.amazonaws.com/evaluation-service:latest
docker tag tech-challenge-02-analytics-service:latest  123456789012.dkr.ecr.us-east-2.amazonaws.com/analytics-service:latest
```

### 4.5 Enviar as imagens para o ECR

```powershell
docker push 123456789012.dkr.ecr.us-east-2.amazonaws.com/auth-service:latest
docker push 123456789012.dkr.ecr.us-east-2.amazonaws.com/flag-service:latest
docker push 123456789012.dkr.ecr.us-east-2.amazonaws.com/targeting-service:latest
docker push 123456789012.dkr.ecr.us-east-2.amazonaws.com/evaluation-service:latest
docker push 123456789012.dkr.ecr.us-east-2.amazonaws.com/analytics-service:latest
```

> O upload pode demorar alguns minutos dependendo da sua internet.

### 4.6 Atualizar os Deployments com as URLs do ECR

Abra cada arquivo abaixo e substitua o campo `image:` pela URL real:

| Arquivo | Valor do campo `image:` |
|---|---|
| `infra/k8s/auth-service/deployment.yaml` | `123456789012.dkr.ecr.us-east-2.amazonaws.com/auth-service:latest` |
| `infra/k8s/flag-service/deployment.yaml` | `123456789012.dkr.ecr.us-east-2.amazonaws.com/flag-service:latest` |
| `infra/k8s/targeting-service/deployment.yaml` | `123456789012.dkr.ecr.us-east-2.amazonaws.com/targeting-service:latest` |
| `infra/k8s/evaluation-service/deployment.yaml` | `123456789012.dkr.ecr.us-east-2.amazonaws.com/evaluation-service:latest` |
| `infra/k8s/analytics-service/deployment.yaml` | `123456789012.dkr.ecr.us-east-2.amazonaws.com/analytics-service:latest` |

---

## 5. Criar os bancos de dados RDS (PostgreSQL)

> **O que é RDS?** É o "banco de dados gerenciado" da AWS — você não precisa instalar ou manter o PostgreSQL. A Amazon cuida de tudo.

> ⚠️ **Limite do plano gratuito:** a conta só permite **2 instâncias RDS** simultâneas — a 3ª falha
> com "maximum number of instances available with free plan accounts". Por isso, criamos **2 RDS**
> (auth e flags) e o banco do **targeting roda como pod dentro do EKS**
> (manifestos em `infra/k8s/postgres-targeting/`, com disco EBS persistente). Solução aprovada pelo professor (D-001).

Você vai criar **2 instâncias RDS**. O processo é o mesmo para as 2 — repita os passos abaixo mudando apenas o nome.

### Para cada banco de dados:

1. Na busca do console AWS, digite **RDS** e clique no serviço
2. Clique em **Criar banco de dados**
3. Escolha **Criação padrão**
4. Em **Mecanismo**, selecione **PostgreSQL**
5. Em **Modelos**, selecione **Nível gratuito** (Free Tier)

### Configurações (repita 2 vezes com os nomes abaixo):

| Campo | Banco 1 (auth) | Banco 2 (flags) |
|---|---|---|
| Identificador da instância | `togglemaster-auth` | `togglemaster-flags` |
| Nome do banco inicial | `auth_db` | `flags_db` |
| Nome de usuário | `toggle` | `toggle` |
| Senha | Escolha uma senha forte | Mesma senha |
| Classe da instância | `db.t3.micro` | `db.t3.micro` |
| Armazenamento | 20 GB (mínimo) | 20 GB |
| Acesso público | **Sim** (para testes) | **Sim** |

> 🐘 **E o targeting_db?** Não é criado aqui — ele sobe junto com o deploy no Kubernetes
> (`kubectl apply -f infra/k8s/postgres-targeting/`), depois que o cluster e o EBS CSI Driver
> existirem. O serviço de targeting acessa esse banco pelo endereço interno `postgres-targeting:5432`.

6. Em **Grupos de segurança VPC**, anote qual VPC e security group foram usados (você precisará do mesmo para o EKS)
7. Clique em **Criar banco de dados**
8. Aguarde o status mudar para **Disponível** (pode demorar 5–10 min)

### Anotar os endpoints:

Após criar cada banco, clique nele e copie o **Endpoint**. Será algo como:
```
togglemaster-auth.abc123xyz.us-east-2.rds.amazonaws.com
```

Salve no seu `.env`:
```env
AUTH_DATABASE_URL=postgres://toggle:SuaSenha@togglemaster-auth.abc123xyz.us-east-2.rds.amazonaws.com:5432/auth_db
FLAGS_DATABASE_URL=postgres://toggle:SuaSenha@togglemaster-flags.abc123xyz.us-east-2.rds.amazonaws.com:5432/flags_db

# O targeting NÃO usa RDS: o banco roda como pod no cluster.
# No secret do Kubernetes, a URL aponta para o Service interno:
TARGETING_DATABASE_URL=postgres://toggle:SuaSenha@postgres-targeting:5432/targeting_db
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
AWS_REGION=us-east-2
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
https://sqs.us-east-2.amazonaws.com/123456789012/togglemaster-events
```

Salve no `.env`:
```env
AWS_SQS_URL=https://sqs.us-east-2.amazonaws.com/123456789012/togglemaster-events
```

---

## 9. Criar o cluster Kubernetes (EKS)

> **O que é EKS?** É o Kubernetes gerenciado da Amazon — você não precisa configurar o Kubernetes manualmente. A Amazon mantém o "cérebro" do cluster.

> ⚠️ **Atenção ao custo:** O cluster EKS cobra **~R$0,55/hora** pelo control plane, independente de estar sendo usado. Crie **somente quando for fazer o deploy e gravar o vídeo**.

### Como foi feito de verdade: pelo console (em 2 etapas)

> ℹ️ No deploy real (2026-06-29 e 2026-07-06), o cluster foi criado pelo **console AWS**, não pelo eksctl:
>
> 1. **Control plane:** EKS → Create cluster → nome `togglemaster-cluster`, K8s 1.30, endpoint
>    "Public and private", role `togglemaster-eks-cluster-role`. Add-ons marcados: CoreDNS,
>    kube-proxy, VPC CNI, **EKS Pod Identity Agent** e **Metrics Server** (já cobre o HPA).
> 2. **Node group:** aba Compute → Add node group → nome `workers`, role `togglemaster-eks-node-role`,
>    Amazon Linux 2023, **c7i-flex.large** (⚠️ o plano gratuito BLOQUEIA t3.medium — "not eligible
>    for Free Tier"), disco 20 GiB, Min 1 / Desejado 2 / Máx 4, nas 2 sub-redes públicas.
> 3. **EBS CSI Driver:** aba Add-ons → Amazon EBS CSI Driver → criar a role via Pod Identity.
>    Depois, marcar a StorageClass `gp2` como padrão:
>    `kubectl patch storageclass gp2 -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'`

### Alternativa: criar com eksctl (um comando só)

```powershell
eksctl create cluster `
  --name togglemaster-cluster `
  --region us-east-2 `
  --nodegroup-name workers `
  --node-type c7i-flex.large `
  --nodes 2 `
  --nodes-min 1 `
  --nodes-max 4 `
  --managed
```

> Este comando cria o cluster E os servidores (nós) automaticamente. Demora cerca de **15–20 minutos**.

### Conectar o kubectl ao cluster:

```powershell
aws eks update-kubeconfig --region us-east-2 --name togglemaster-cluster
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
abc123.us-east-2.elb.amazonaws.com
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
| `analytics-service/configmap.yaml` | `AWS_REGION` | `us-east-2` |

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

O que custa dinheiro **parado** é: os nós EC2 do node group (~US$ 0,17/h com 2× c7i-flex.large) e o
Load Balancer do Nginx (~US$ 0,02/h). O resto (RDS db.t3.micro, SQS, DynamoDB, ElastiCache t3.micro,
ECR, o control plane que o Free Tier cobre) é grátis ou quase grátis — pode deixar.

```powershell
# 1. Remover o Nginx Ingress (isso APAGA o Load Balancer público)
kubectl delete namespace ingress-nginx

# 2. Zerar as máquinas do node group (console: cluster -> Compute -> workers -> Edit -> Desired 0)
#    Ou deletar o node group de vez. O control plane pode ficar (coberto pelo Free Tier).

# 3. (Opcional, fim do projeto) Deletar os bancos RDS
aws rds delete-db-instance --db-instance-identifier togglemaster-auth  --skip-final-snapshot --region us-east-2
aws rds delete-db-instance --db-instance-identifier togglemaster-flags --skip-final-snapshot --region us-east-2

# 4. (Opcional, fim do projeto) Deletar o ElastiCache
aws elasticache delete-replication-group --replication-group-id togglemaster-redis --region us-east-2

# 5. (Opcional, fim do projeto) Deletar a fila SQS
aws sqs delete-queue --queue-url https://sqs.us-east-2.amazonaws.com/891376952395/togglemaster-events

# 6. As imagens no ECR e a tabela DynamoDB ficam no Free Tier — pode deixar
```

> 💡 **Para religar a demo depois:** volte o Desired do node group para 2, reaplique o Nginx Ingress
> (`kubectl apply` do manifesto oficial) e rode `kubectl apply -f infra/k8s/ingress.yaml`.
> Atenção: o endereço do Load Balancer MUDA a cada recriação.

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
| Banco do targeting (pod) | `postgres-targeting:5432` (Service interno do cluster) | `TARGETING_DATABASE_URL` |
| ElastiCache endpoint | `togglemaster-redis.xxx.cache.amazonaws.com` | `REDIS_URL` |
| SQS URL | `https://sqs.us-east-2.amazonaws.com/xxx/togglemaster-events` | `AWS_SQS_URL` |
| Load Balancer DNS | `abc123.us-east-2.elb.amazonaws.com` | URL pública do sistema |
