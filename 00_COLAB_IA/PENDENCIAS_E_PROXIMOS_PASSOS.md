# PENDÊNCIAS E PRÓXIMOS PASSOS

> **TL;DR:** Backlog priorizado (P-###) e achados (F-###). O **control plane do cluster EKS já está criado e Active**. **PRÓXIMA TAREFA: criar o NODE GROUP** (as máquinas) — 2× t3.medium, Min 1 / Desejado 2 / Máx 4. Depois: EBS CSI → Nginx Ingress → conectar kubectl → preencher secrets → deploy → vídeo.
>
> **Última atualização:** 2026-06-29 — Claude (Opus 4.8).

## Concluído

### 2026-06-29 (via console AWS)
- ✅ **Rede pronta — F-003 resolvido.** O VPC `vpc-03a557849629939d0` já tinha 4 sub-redes em 2 AZs (mapa no DOSSIE §4). Tag `kubernetes.io/role/elb=1` adicionada nas 2 sub-redes públicas (pré-requisito do Load Balancer do Nginx).
- ✅ **IAM roles criadas** (conta pessoal, sem LabRole): `togglemaster-eks-cluster-role` (policy `AmazonEKSClusterPolicy`) e `togglemaster-eks-node-role` (policies `AmazonEKSWorkerNodePolicy` + `AmazonEC2ContainerRegistryReadOnly` + `AmazonEKS_CNI_Policy`).
- ✅ **P-004a — Control plane do cluster EKS `togglemaster-cluster` criado e Active** (pelo console, NÃO eksctl). K8s 1.30, endpoint Public and private, sem scaling tier, sem Auto Mode, Bootstrap admin = Allow.
  - Add-ons: CoreDNS, kube-proxy, Amazon VPC CNI, **EKS Pod Identity Agent**, Node monitoring agent e **Metrics Server** (community add-on — já cumpre o pré-requisito do HPA; **não** precisa mais instalar o Metrics Server via kubectl).
  - Observability/logs do control plane: DESLIGADOS (evita custo CloudWatch).
- ✅ **Manifestos enxugados (D-006 — "entrega mínima FIAP"):** os 5 serviços com `replicas: 1`; HPA de evaluation e analytics em `min 1 / max 2`. Só evaluation e analytics escalam (1→2 sob carga), que é exatamente o que o PDF exige.

### 2026-06-25
- ✅ **P-001 — DynamoDB `ToggleMasterAnalytics`** (us-east-2, chave `event_id` String).
- ✅ **P-002 — SQS `togglemaster-events`** (Standard). URL: `https://sqs.us-east-2.amazonaws.com/891376952395/togglemaster-events`
- ✅ **P-003 — ElastiCache `togglemaster-redis`** (Redis OSS 7.1, `cache.t3.micro`, sub-rede privada). Endpoint `togglemaster-redis.ewbn3x.ng.0001.use2.cache.amazonaws.com:6379` — já no `evaluation-service/configmap.yaml`. SG `sg-0e79721741070ef64` com 6379 liberado p/ 10.0.0.0/16.

## ⏭️ PRÓXIMA TAREFA — P-004b: Criar o node group (as máquinas)
Cluster já Active. Criar o grupo de nós pelo **console** (custo ~US$ 0,08/h — ligar só p/ testar/gravar e derrubar depois).

Passo a passo (console):
1. Abrir o cluster `togglemaster-cluster` → aba **Compute** → **Add node group**.
2. **Name:** `workers` · **Node IAM role:** `togglemaster-eks-node-role` → Next.
3. **AMI:** Amazon Linux 2023 · **Instance type:** **t3.medium** · **Disk:** 20 GiB · **Scaling:** Min 1 / Desired 2 / Max 4 → Next.
4. **Subnets:** as 2 públicas (`subnet-020ef26c5b392069e` + `subnet-042a13d25a15bc975`) · SSH access desativado → Next.
5. **Review and create** → Create (~3–5 min até os nós ficarem Ready).

> Por que t3.medium e 2 nós: t3.micro (Free Tier) é inviável (limite ~4 pods/nó — só os DaemonSets já enchem — + 1 GB RAM); 1 nó só não deixa o HPA escalar (os pods novos ficariam Pending). Ver D-006.

## A fazer (depois do node group)
- **P-004c — EBS CSI Driver** (necessário para o disco do pod targeting). Como o **EKS Pod Identity Agent** já está instalado, dá para adicionar pelo **console** (aba Add-ons → Amazon EBS CSI Driver → criar a role recomendada via Pod Identity). Alternativa por linha de comando (eksctl/OIDC) no fim deste arquivo.
- **P-004d — Nginx Ingress Controller** (via Helm ou kubectl) — cria o Load Balancer público. (Metrics Server JÁ instalado — pular esse passo.)
- **Conectar o kubectl:** `aws eks update-kubeconfig --region us-east-2 --name togglemaster-cluster`. As credenciais IAM de deploy **já estão configuradas** (`aws configure` feito e validado; valores na memória privada do Claude — não versionados).
- **P-005 — Preencher secrets/configmaps e deploy** (`kubectl apply -f infra/k8s/...`). Checklist no fim. Inclui aplicar `infra/k8s/postgres-targeting/` (precisa do EBS CSI antes) e criar a `SERVICE_API_KEY` de produção.
- **P-006 — Atualizar `GUIA-AWS.md`** (us-east-2 + 2 RDS + 1 pod + ElastiCache, em vez de 3 RDS/us-east-1). Ver F-002.
- **P-007 — Gravar o vídeo da demo** (até 20 min: local + nuvem + escalabilidade). Roteiro nos entregáveis do PDF.
- **P-008 — Relatório de entrega:** faltam os RMs de João Ciardullo, Douglas, Felipe Brito e João Gabriel.

## Achados (F-###)
- **F-001 — Inconsistência de região** (us-east-1 vs us-east-2). ✅ RESOLVIDO (commit 498f703).
- **F-002 — `GUIA-AWS.md` desatualizado** (3 RDS, us-east-1). Pendente (P-006); tem aviso no topo do arquivo.
- **F-003 — VPC em 2 AZs.** ✅ RESOLVIDO em 2026-06-29: ao auditar as sub-redes, descobrimos que o VPC já tinha sub-redes em us-east-2a **e** us-east-2b (4 no total). O dossiê antigo estava incompleto (só listava as de 2a). Mapa correto no DOSSIE §4.

## Comandos prontos: EBS CSI Driver (alternativa por linha de comando)
Recomendado fazer pelo console (Pod Identity). Mas se preferir linha de comando, rodar DEPOIS que o node group existir (us-east-2, account 891376952395):
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
Todos os secrets têm placeholders. Região us-east-2. Usuário dos bancos: `toggle`. **A senha dos bancos e a chave IAM já são conhecidas** (memória privada do Claude — NÃO versionar os valores aqui).
- `auth-service/secret.yaml` → `DATABASE_URL` = postgres://toggle:SENHA@<endpoint-rds-auth>:5432/auth_db · `MASTER_KEY` = (master key de produção)
- `flag-service/secret.yaml` → `DATABASE_URL` = postgres://toggle:SENHA@<endpoint-rds-flags>:5432/flags_db
- `targeting-service/secret.yaml` → `DATABASE_URL` = postgres://toggle:SENHA@**postgres-targeting**:5432/targeting_db (aponta para o POD, não RDS)
- `postgres-targeting/secret.yaml` → `POSTGRES_PASSWORD` = a mesma senha (este usa **stringData**, texto puro — sem Base64)
- `evaluation-service/secret.yaml` → `SERVICE_API_KEY` (criar em produção) · `AWS_SQS_URL` = https://sqs.us-east-2.amazonaws.com/891376952395/togglemaster-events · `AWS_ACCESS_KEY_ID` · `AWS_SECRET_ACCESS_KEY`
- `analytics-service/secret.yaml` → `AWS_SQS_URL` (mesma URL) · `AWS_ACCESS_KEY_ID` · `AWS_SECRET_ACCESS_KEY`
- `evaluation-service/configmap.yaml` → `REDIS_URL` ✅ JÁ PREENCHIDO (`redis://togglemaster-redis.ewbn3x.ng.0001.use2.cache.amazonaws.com:6379`)
> Secrets em `data:` precisam de Base64 (PowerShell: `[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("valor"))`). Exceção: `postgres-targeting/secret.yaml` usa `stringData` (texto puro).
