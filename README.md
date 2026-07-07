<div align="center">

# 🚩 ToggleMaster

### Plataforma de Feature Flags distribuída em microsserviços

*Ligue e desligue funcionalidades do seu app em tempo real — sem atualizar o código.*

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Go](https://img.shields.io/badge/Go-1.22-00ADD8?logo=go&logoColor=white)](https://go.dev/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20RDS%20%7C%20SQS%20%7C%20DynamoDB-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/)

---

**Tech Challenge — Fase 2 | POSTECH FIAP**

[📋 Enunciado do Desafio](./POSTECH%20-%20Tech%20Challenge%20-%20Fase%202.pdf) · [📦 Repositório do Projeto](https://github.com/fiap-devops-arqcloud-2026/tech-challenge-02) · [☸️ Manifests Kubernetes](./infra/k8s/)

</div>

---

## 📑 Índice

- [O que é o ToggleMaster?](#-o-que-é-o-togglemaster)
- [Arquitetura](#-arquitetura)
- [Os 5 Microsserviços](#-os-5-microsserviços)
- [Pré-requisitos](#-pré-requisitos)
- [Rodando Localmente](#-rodando-localmente)
- [Testando o Sistema](#-testando-o-sistema)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Deploy na AWS (Kubernetes)](#-deploy-na-aws-kubernetes)
- [Time](#-time)

---

## 💡 O que é o ToggleMaster?

Imagine que você tem um aplicativo com milhões de usuários e quer lançar uma nova funcionalidade — por exemplo, um novo painel de controle. Você não quer mostrar para todo mundo de uma vez. Quer testar primeiro com 10% dos usuários, ver se funciona, e ir aumentando gradualmente.

**O ToggleMaster é exatamente essa ferramenta.** Ele permite criar "interruptores" (chamados de *feature flags*) que ligam e desligam funcionalidades do seu app em tempo real, sem precisar fazer uma nova atualização ou reiniciar o sistema.

### Por que isso é útil?

| Situação | Sem ToggleMaster | Com ToggleMaster |
|---|---|---|
| Lançar nova funcionalidade | Atualiza o app para todos de uma vez 😰 | Liga para 10% dos usuários primeiro ✅ |
| Encontrou um bug em produção | Novo deploy de emergência 😱 | Desliga a flag em segundos ✅ |
| Teste A/B | Código duplicado complexo 🤯 | Regra de porcentagem simples ✅ |
| Funcionalidade por região | Lógica espalhada no código 😵 | Regra de segmentação centralizada ✅ |

---

## 🏗️ Arquitetura

O sistema é composto por **5 microsserviços independentes** que se comunicam entre si:

```
                          ┌─────────────────────────────────┐
                          │         SEU APLICATIVO          │
                          │   (mobile, web, API, etc.)      │
                          └────────────────┬────────────────┘
                                           │
                          ┌────────────────▼────────────────┐
                          │         NGINX INGRESS           │  ← Porta de entrada pública
                          │  /evaluate  /flags  /rules      │
                          └──┬──────────┬──────────┬────────┘
                             │          │          │
               ┌─────────────▼──┐  ┌───▼────┐  ┌─▼──────────────┐
               │ evaluation-svc │  │  flag  │  │   targeting    │
               │   🚀 Go        │  │  svc   │  │     svc        │
               │ (hot path)     │  │ 🐍 Py  │  │    🐍 Py       │
               │ porta: 8004    │  │ :8002  │  │    :8003       │
               └───┬────────────┘  └───┬────┘  └─────┬──────────┘
                   │                   └──────┬────────┘
                   │              ┌────────────▼──────────────┐
                   │              │       auth-service        │
                   │              │         🔐 Go             │
                   │              │  Valida chaves de API     │
                   │              │       porta: 8001         │
                   │              └───────────────────────────┘
                   │
          ┌────────▼────────┐         ┌──────────────────────┐
          │    AWS SQS      │────────►│   analytics-service  │
          │  Fila de eventos│         │       🐍 Python       │
          └─────────────────┘         │  Worker: SQS→DynamoDB│
                                      │      porta: 8005      │
                                      └──────────┬───────────┘
                                                 │
                                      ┌──────────▼───────────┐
                                      │    AWS DynamoDB      │
                                      │  Dados de análise    │
                                      └──────────────────────┘
```

### Bancos de Dados

| Serviço | Banco | Tecnologia | Propósito |
|---|---|---|---|
| auth-service | `auth_db` | PostgreSQL (RDS) | Armazena hashes das chaves de API |
| flag-service | `flags_db` | PostgreSQL (RDS) | Definições das feature flags |
| targeting-service | `targeting_db` | PostgreSQL (**pod no EKS** + disco EBS) | Regras de segmentação |
| evaluation-service | — | Redis (ElastiCache) | Cache de 30s para respostas ultra-rápidas |
| analytics-service | `ToggleMasterAnalytics` | DynamoDB | Histórico de avaliações |

> 💡 **Por que o targeting não usa RDS?** O plano gratuito da AWS limita a conta a 2 instâncias RDS. O banco do targeting roda como um pod PostgreSQL dentro do cluster ([infra/k8s/postgres-targeting/](./infra/k8s/postgres-targeting/)) — solução aprovada pelo professor. Detalhes em [docs/ARQUITETURA.md](./docs/ARQUITETURA.md).

---

## 🔧 Os 5 Microsserviços

### 🔐 auth-service — O Segurança
**Linguagem:** Go · **Porta:** 8001 · **Banco:** PostgreSQL

Gerencia a autenticação de toda a plataforma. Cria e valida as **chaves de API** (chamadas de `tm_key_...`) que protegem todos os outros serviços.

→ [Ver documentação completa](./services/auth-service/README.md)

---

### 🚩 flag-service — O Painel de Controle
**Linguagem:** Python · **Porta:** 8002 · **Banco:** PostgreSQL

Gerencia o cadastro das feature flags: criar, listar, ativar, desativar e deletar. É aqui que você define quais "interruptores" existem no sistema.

→ [Ver documentação completa](./services/flag-service/README.md)

---

### 🎯 targeting-service — O Selecionador
**Linguagem:** Python · **Porta:** 8003 · **Banco:** PostgreSQL

Define as **regras de quem vê cada funcionalidade**. Suporta regras por porcentagem (ex: "50% dos usuários"), podendo ser estendido para regras por país, plano, etc.

→ [Ver documentação completa](./services/targeting-service/README.md)

---

### ⚡ evaluation-service — O Juiz Rápido
**Linguagem:** Go · **Porta:** 8004 · **Cache:** Redis

O coração do sistema. Recebe a pergunta `"O usuário X deve ver a feature Y?"` e responde `true` ou `false` em milissegundos usando cache Redis. É o serviço que seu app chama o tempo todo.

→ [Ver documentação completa](./services/evaluation-service/README.md)

---

### 📊 analytics-service — O Contador de Eventos
**Linguagem:** Python · **Porta:** 8005 · **Infraestrutura:** SQS + DynamoDB

Worker silencioso que roda em segundo plano. Consome os eventos da fila SQS (publicados pelo evaluation-service) e salva os dados de análise no DynamoDB.

→ [Ver documentação completa](./services/analytics-service/README.md)

---

## 📋 Pré-requisitos

Para rodar o projeto localmente, você precisa ter instalado:

| Ferramenta | Versão mínima | Download |
|---|---|---|
| **Docker Desktop** | 24.x | [docker.com](https://www.docker.com/products/docker-desktop/) |
| **Docker Compose** | 2.x | Incluído no Docker Desktop |
| **Git** | 2.x | [git-scm.com](https://git-scm.com/) |

> ⚠️ **Não é necessário** instalar Go, Python, PostgreSQL ou Redis separadamente. O Docker cuida de tudo.

---

## 🚀 Rodando Localmente

### 1. Clone o repositório

```bash
git clone https://github.com/fiap-devops-arqcloud-2026/tech-challenge-02.git
cd tech-challenge-02
```

### 2. Configure as variáveis de ambiente

```bash
# Copia o arquivo de exemplo para o arquivo real
# Windows (PowerShell):
Copy-Item .env.example .env

# Linux/Mac:
cp .env.example .env
```

> O `.env.example` já vem com todos os valores configurados para o ambiente local. Não é necessário alterar nada para rodar.

### 3. Suba todos os containers

```bash
docker compose up --build -d
```

Esse comando vai:
- Construir as imagens dos 5 serviços
- Subir os 4 bancos de dados (2× PostgreSQL, Redis, DynamoDB Local)
- Iniciar os 5 microsserviços
- Criar e configurar os bancos automaticamente

### 4. Verifique se tudo subiu corretamente

```bash
docker compose ps
```

Aguarde até todos aparecerem como `healthy`. Pode levar cerca de 30-60 segundos na primeira vez.

**Resultado esperado:**

```
NAME                                    STATUS
tech-challenge-02-postgres-auth-1       running (healthy)
tech-challenge-02-postgres-app-1        running (healthy)
tech-challenge-02-redis-1               running (healthy)
tech-challenge-02-dynamodb-local-1      running
tech-challenge-02-auth-service-1        running (healthy)
tech-challenge-02-flag-service-1        running (healthy)
tech-challenge-02-targeting-service-1   running (healthy)
tech-challenge-02-evaluation-service-1  running (healthy)
tech-challenge-02-analytics-service-1   running (healthy)
```

### 5. Confirme que todos os serviços respondem

```bash
# Windows (PowerShell):
curl.exe http://localhost:8001/health
curl.exe http://localhost:8002/health
curl.exe http://localhost:8003/health
curl.exe http://localhost:8004/health
curl.exe http://localhost:8005/health

# Linux/Mac:
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:8004/health
curl http://localhost:8005/health
```

Todos devem responder: `{"status":"ok"}`

### Comandos úteis

```bash
# Ver logs de um serviço específico
docker compose logs auth-service -f

# Ver logs de todos os serviços
docker compose logs -f

# Parar tudo (mantém os dados)
docker compose down

# Parar tudo e apagar os dados dos bancos
docker compose down -v

# Reiniciar um serviço específico
docker compose restart evaluation-service
```

---

## 🧪 Testando o Sistema

Após subir o ambiente, siga este roteiro para testar o fluxo completo:

### Passo 1 — Criar uma chave de API

```bash
# Windows (PowerShell):
curl.exe -X POST http://localhost:8001/admin/keys `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer admin-secreto-123" `
  -d '{\"name\": \"minha-chave\"}'

# Linux/Mac:
curl -X POST http://localhost:8001/admin/keys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer admin-secreto-123" \
  -d '{"name": "minha-chave"}'
```

Guarde o valor de `"key"` retornado (ex: `tm_key_abc123...`). Você vai usar nos próximos passos.

### Passo 2 — Criar uma feature flag

```bash
# Substitua SUA_CHAVE pelo valor retornado no passo anterior

# Windows (PowerShell):
curl.exe -X POST http://localhost:8002/flags `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer SUA_CHAVE" `
  -d '{\"name\": \"novo-dashboard\", \"description\": \"Ativa o novo dashboard\", \"is_enabled\": true}'

# Linux/Mac:
curl -X POST http://localhost:8002/flags \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SUA_CHAVE" \
  -d '{"name": "novo-dashboard", "description": "Ativa o novo dashboard", "is_enabled": true}'
```

### Passo 3 — Criar uma regra de segmentação (50% dos usuários)

```bash
# Windows (PowerShell):
curl.exe -X POST http://localhost:8003/rules `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer SUA_CHAVE" `
  -d '{\"flag_name\": \"novo-dashboard\", \"is_enabled\": true, \"rules\": {\"type\": \"PERCENTAGE\", \"value\": 50}}'

# Linux/Mac:
curl -X POST http://localhost:8003/rules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SUA_CHAVE" \
  -d '{"flag_name": "novo-dashboard", "is_enabled": true, "rules": {"type": "PERCENTAGE", "value": 50}}'
```

### Passo 4 — Avaliar a flag para diferentes usuários

```bash
# Avalia para vários usuários (alguns recebem true, outros false — é esperado!)
curl.exe "http://localhost:8004/evaluate?user_id=usuario-1&flag_name=novo-dashboard"
curl.exe "http://localhost:8004/evaluate?user_id=usuario-2&flag_name=novo-dashboard"
curl.exe "http://localhost:8004/evaluate?user_id=usuario-3&flag_name=novo-dashboard"
```

Respostas esperadas (exemplo):
```json
{"flag_name":"novo-dashboard","user_id":"usuario-1","result":true}
{"flag_name":"novo-dashboard","user_id":"usuario-2","result":false}
{"flag_name":"novo-dashboard","user_id":"usuario-3","result":true}
```

> 💡 **O mesmo usuário sempre recebe a mesma resposta** — o sistema usa um algoritmo determinístico. Se `usuario-1` recebeu `true`, sempre receberá `true` para essa flag.

### Passo 5 — Verificar o cache Redis

Execute o mesmo comando duas vezes seguidas e observe os logs:

```bash
docker compose logs evaluation-service --tail=5
```

Na segunda chamada você verá `Cache HIT` — significa que o Redis respondeu sem consultar os outros serviços, tornando a resposta muito mais rápida.

---

## 📁 Estrutura do Projeto

```
tech-challenge-02/
│
├── 📄 docker-compose.yaml          # Orquestra os 9 containers localmente
├── 📄 .env.example                 # Template de configuração (copie para .env)
├── 📄 .env                         # Suas configurações locais (não vai para o git)
│
├── 📂 services/                    # Código-fonte dos 5 microsserviços
│   ├── 📂 auth-service/            # 🔐 Go — autenticação e chaves de API
│   ├── 📂 flag-service/            # 🚩 Python — CRUD de feature flags
│   ├── 📂 targeting-service/       # 🎯 Python — regras de segmentação
│   ├── 📂 evaluation-service/      # ⚡ Go — avaliação em tempo real (hot path)
│   └── 📂 analytics-service/       # 📊 Python — worker SQS → DynamoDB
│
├── 📂 docs/
│   ├── 📄 ARQUITETURA.md           # 🏛️ Arquitetura, decisões e dificuldades (com diagrama)
│   └── 📂 apresentacao/            # 🎨 Apresentação do projeto (.pptx)
│
├── 📂 00_COLAB_IA/                 # 🤝 Contexto de colaboração (log, pendências, decisões)
│
└── 📂 infra/
    ├── 📂 postgres-app/            # Script de inicialização do banco local
    └── 📂 k8s/                     # ☸️ Manifests Kubernetes para o AWS EKS
        ├── 📄 00-namespaces.yaml
        ├── 📂 auth-service/        # Secret, ConfigMap, Deployment, Service
        ├── 📂 flag-service/        # Secret, ConfigMap, Deployment, Service
        ├── 📂 targeting-service/   # Secret, ConfigMap, Deployment, Service
        ├── 📂 postgres-targeting/  # 🐘 Banco do targeting como pod (StatefulSet + EBS)
        ├── 📂 evaluation-service/  # Secret, ConfigMap, Deployment, Service, HPA
        ├── 📂 analytics-service/   # Secret, ConfigMap, Deployment, Service, HPA
        └── 📄 ingress.yaml         # Roteamento externo via Nginx
```

---

## ☸️ Deploy na AWS (Kubernetes)

> ✅ **O deploy foi realizado em 2026-07-06** — os 5 microsserviços rodaram em produção no cluster EKS `togglemaster-cluster` (região **us-east-2/Ohio**), com escalabilidade demonstrada no vídeo da entrega. A arquitetura completa, as decisões e as dificuldades estão documentadas em [docs/ARQUITETURA.md](./docs/ARQUITETURA.md).

Os manifests Kubernetes estão em [`infra/k8s/`](./infra/k8s/).

### Infraestrutura utilizada na AWS

| Recurso | Serviço AWS | Para quê |
|---|---|---|
| Cluster Kubernetes | EKS (2 nós c7i-flex.large, auto scaling 1–4) | Orquestrar os containers |
| 5 repositórios de imagem | ECR | Armazenar as imagens Docker |
| 2 bancos de dados | RDS (PostgreSQL) | auth e flag services |
| 1 banco em pod | PostgreSQL no EKS + disco EBS | targeting service (limite de 2 RDS no plano gratuito) |
| Cache em memória | ElastiCache (Redis) | evaluation-service |
| Banco NoSQL | DynamoDB | analytics-service |
| Fila de mensagens | SQS | Comunicação evaluation → analytics |

### Aplicando os manifests

```bash
# 1. Conecte seu kubectl ao cluster EKS (região us-east-2)
aws eks update-kubeconfig --region us-east-2 --name togglemaster-cluster

# 2. Crie o namespace
kubectl apply -f infra/k8s/00-namespaces.yaml

# 3. Suba primeiro o banco do targeting (pod com disco EBS)
kubectl apply -f infra/k8s/postgres-targeting/

# 4. Aplique os recursos de cada serviço
kubectl apply -f infra/k8s/auth-service/
kubectl apply -f infra/k8s/flag-service/
kubectl apply -f infra/k8s/targeting-service/
kubectl apply -f infra/k8s/evaluation-service/
kubectl apply -f infra/k8s/analytics-service/

# 5. Configure o Ingress (cria o Load Balancer público)
kubectl apply -f infra/k8s/ingress.yaml

# 6. Verifique se os pods estão rodando
kubectl get pods -n togglemaster
```

> ℹ️ **Pré-requisitos no cluster:** EBS CSI Driver (para o disco do pod targeting), Metrics Server (para os HPAs) e Nginx Ingress Controller. O passo a passo completo — incluindo a criação do cluster e do node group pelo console — está no [GUIA-AWS.md](./GUIA-AWS.md).
>
> ⚠️ **Sobre os secrets:** este repositório é **privado** e usado como laboratório da disciplina — os `secret.yaml` estão preenchidos com os valores reais do ambiente de demonstração. Num projeto real, secrets **nunca** são versionados.

---

## 👥 Time

Projeto desenvolvido para a **Fase 2 do Tech Challenge** da pós-graduação em **DevOps e Arquitetura Cloud** — POSTECH FIAP.

| Integrante | RM | GitHub |
|---|---|---|
| Gabriel Silva | RM373763 | [@Tocaccelli](https://github.com/Tocaccelli) |
| João Ciardullo | — | [@joaociardullo](https://github.com/joaociardullo) |
| Douglas | — | [@Douglasdeveza](https://github.com/Douglasdeveza) |
| Felipe Brito | — | [@Durmiand](https://github.com/Durmiand) |
| João Gabriel | — | [@jgabrieldev1](https://github.com/jgabrieldev1) |

---

<div align="center">

Feito com ☕ e muito Kubernetes

</div>
