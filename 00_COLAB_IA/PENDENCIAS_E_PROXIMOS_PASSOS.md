# PENDÊNCIAS E PRÓXIMOS PASSOS

> **TL;DR:** Backlog priorizado (P-###) e achados (F-###). **PRÓXIMA TAREFA: criar o cluster EKS (P-004)** — passo "dia da gravação". ⚠️ ANTES, criar uma sub-rede pública em us-east-2b (F-003). Depois: add-ons, preencher secrets (checklist no fim) e deploy.
>
> **Última atualização:** 2026-06-28 19:52 (BRT) — Claude (Opus 4.8).

## Concluído (2026-06-25)
- ✅ **P-001 — DynamoDB `ToggleMasterAnalytics`** (us-east-2, chave `event_id` String).
- ✅ **P-002 — SQS `togglemaster-events`** (Standard, us-east-2). URL: `https://sqs.us-east-2.amazonaws.com/891376952395/togglemaster-events`
- ✅ **P-003 — ElastiCache `togglemaster-redis`** (Redis OSS 7.1, `cache.t3.micro`, 0 réplicas, sub-rede privada, encryption-in-transit OFF).
  - Endpoint: `togglemaster-redis.ewbn3x.ng.0001.use2.cache.amazonaws.com:6379` — já no `evaluation-service/configmap.yaml` (commit 7081e5a).
  - SG `sg-0e79721741070ef64`: regra de entrada **6379** (origem `10.0.0.0/16`) ✅ adicionada.

## ⏭️ PRÓXIMA TAREFA — P-004: Criar o cluster EKS
Passo "dia da gravação" (o EKS custa ~US$0,10/h — criar só quando for testar/gravar e derrubar depois).

⚠️ **PRÉ-REQUISITO DE REDE (F-003):** o EKS exige sub-redes em **pelo menos 2 AZs**, mas o VPC só tem sub-redes em **us-east-2a**. ANTES de criar o cluster, criar uma **sub-rede pública adicional em us-east-2b** (ex.: `10.0.20.0/24`) no VPC `vpc-03a557849629939d0`, associada à mesma route table pública (com o IGW `igw-0364461e4d4226f8b`). Sem isso o `eksctl` falha no control plane.

Comando (depois de ter as 2 sub-redes públicas — 2a + a nova 2b):
```powershell
eksctl create cluster `
  --name togglemaster-cluster --region us-east-2 --version 1.30 `
  --vpc-public-subnets subnet-020ef26c5b392069e,<SUBNET_PUBLICA_us-east-2b> `
  --nodegroup-name workers --node-type t3.small `
  --nodes 2 --nodes-min 1 --nodes-max 4 --managed
```

Depois do cluster pronto, na ordem:
1. **EBS CSI Driver** (comandos completos no fim deste arquivo) — necessário para o disco do pod targeting.
2. **Metrics Server** (para o HPA): `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`
3. **Nginx Ingress Controller** (via Helm) — cria o Load Balancer público.
4. Conectar o kubectl: `aws eks update-kubeconfig --region us-east-2 --name togglemaster-cluster`

## A fazer (depois do EKS)
- **P-005 — Preencher secrets/configmaps e fazer deploy** (`kubectl apply -f infra/k8s/...`). Checklist de valores no fim. Inclui aplicar `infra/k8s/postgres-targeting/` (precisa do EBS CSI antes) e criar a SERVICE_API_KEY de produção (POST /admin/keys).
- **P-006 — Atualizar `GUIA-AWS.md`** (região us-east-2 + arquitetura 2 RDS + 1 pod + ElastiCache, em vez de 3 RDS/us-east-1). Há um aviso de "desatualizado" no topo dele. Ver F-002.
- **P-007 — Gravar o vídeo da demo na AWS** (até 20 min: local + nuvem + escalabilidade).
- **P-008 — Relatório de entrega:** faltam os RMs de João Ciardullo, Douglas, Felipe Brito e João Gabriel.

## Achados (F-###)
- **F-001 — Inconsistência de região** (us-east-1 vs us-east-2). ✅ RESOLVIDO (commit 498f703).
- **F-002 — `GUIA-AWS.md` desatualizado** (3 RDS, us-east-1). Pendente (P-006); tem aviso no topo do arquivo.
- **F-003 — VPC só tem sub-redes em us-east-2a**, mas o EKS exige 2 AZs. Criar sub-rede pública em us-east-2b antes do P-004.

## Comandos prontos: EBS CSI Driver (pré-requisito de P-004/P-005, para o disco do pod targeting)
Rodar DEPOIS que o cluster `togglemaster-cluster` existir (us-east-2, account 891376952395):
```powershell
# 1. Ativar OIDC no cluster
eksctl utils associate-iam-oidc-provider --cluster togglemaster-cluster --region us-east-2 --approve

# 2. Criar a IAM service account com a policy do EBS CSI
eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system `
  --cluster togglemaster-cluster --region us-east-2 `
  --role-name AmazonEKS_EBS_CSI_DriverRole `
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --approve

# 3. Instalar o addon usando a role criada
eksctl create addon --name aws-ebs-csi-driver --cluster togglemaster-cluster --region us-east-2 `
  --service-account-role-arn arn:aws:iam::891376952395:role/AmazonEKS_EBS_CSI_DriverRole --force
```

## Checklist: secrets/configmaps a preencher antes do deploy (detalhe de P-005)
Todos os secrets têm placeholders. Região us-east-2. Usuário dos bancos: `toggle`. Senha: a mesma definida pelo Gabriel (NÃO versionada — pedir a ele).
- `auth-service/secret.yaml` → `DATABASE_URL` = postgres://toggle:SENHA@<endpoint-rds-auth>:5432/auth_db · `MASTER_KEY` = (master key de produção)
- `flag-service/secret.yaml` → `DATABASE_URL` = postgres://toggle:SENHA@<endpoint-rds-flags>:5432/flags_db
- `targeting-service/secret.yaml` → `DATABASE_URL` = postgres://toggle:SENHA@**postgres-targeting**:5432/targeting_db (aponta para o POD, não RDS)
- `postgres-targeting/secret.yaml` → `POSTGRES_PASSWORD` = a mesma senha (este usa **stringData**, texto puro — sem Base64)
- `evaluation-service/secret.yaml` → `SERVICE_API_KEY` (criar em produção) · `AWS_SQS_URL` = https://sqs.us-east-2.amazonaws.com/891376952395/togglemaster-events · `AWS_ACCESS_KEY_ID` · `AWS_SECRET_ACCESS_KEY`
- `analytics-service/secret.yaml` → `AWS_SQS_URL` (mesma URL) · `AWS_ACCESS_KEY_ID` · `AWS_SECRET_ACCESS_KEY`
- `evaluation-service/configmap.yaml` → `REDIS_URL` ✅ JÁ PREENCHIDO (`redis://togglemaster-redis.ewbn3x.ng.0001.use2.cache.amazonaws.com:6379`)
> Secrets em `data:` precisam de Base64 (PowerShell: `[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("valor"))`). Exceção: `postgres-targeting/secret.yaml` usa `stringData` (texto puro).
