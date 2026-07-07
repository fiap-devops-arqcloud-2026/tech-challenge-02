# PENDÊNCIAS E PRÓXIMOS PASSOS

> **TL;DR:** Backlog priorizado (P-###) e achados (F-###). **A APLICAÇÃO ESTÁ NO AR na AWS (deploy completo e verificado em 2026-07-06).** LB público: `a4e86e3f9b5564375bcbe8c46ad4acee-fc7302f5c0e6e08e.elb.us-east-2.amazonaws.com`. **PRÓXIMA TAREFA: gravar o vídeo (P-007)** — roteiro no chat de 2026-07-06. ⚠️ Cluster LIGADO (~US$0,19/h); derrubar após a gravação.
>
> **Última atualização:** 2026-07-06 — Claude (Fable 5).

## Concluído

### 2026-07-06 — DEPLOY COMPLETO ✅
- ✅ **P-004b — Node group `workers`** (2× **c7i-flex.large** — t3.medium bloqueada pelo plano gratuito, ver D-007), Min 1/Des 2/Máx 4.
- ✅ **P-004c — EBS CSI Driver** (add-on, Pod Identity). StorageClass `gp2` marcada como default.
- ✅ **P-004d — Nginx Ingress v1.15.1**. LB: `a4e86e3f9b5564375bcbe8c46ad4acee-fc7302f5c0e6e08e.elb.us-east-2.amazonaws.com`.
- ✅ **kubectl conectado** (usuário `togglemaster-deploy` ganhou policy `eks:*` + access entry admin no cluster).
- ✅ **P-005 — Secrets preenchidos (valores reais versionados) e deploy feito.** 6 pods Running. `SERVICE_API_KEY` real no `evaluation-service/secret.yaml`; `MASTER_KEY` = `tm-master-5lQ76l3nYa7LVlDd5w1vTECmYKoxZjR`. Consertos: SG do RDS (5432), `init.sql` do auth e do flags rodados nos RDS.
- ✅ **Verificado ponta a ponta:** flags via LB público, evento SQS→analytics→DynamoDB (1 item), HPAs lendo CPU.

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

## ⏭️ PRÓXIMA TAREFA — Fechar a entrega (P-008)
✅ **Vídeo GRAVADO em 2026-07-06.** O que falta, na ordem:
1. **Subir o vídeo no YouTube** (não listado serve) e guardar o link.
2. **P-008 — Relatório de entrega:** ✅ **PDF GERADO** em `docs/FIAP - Tech Challenge - Fase 2 - Grupo 203.pdf` (todos os 5 Discords confirmados), porém **com placeholder no lugar do link do vídeo** (upload em andamento). **ÚLTIMO PASSO DA FASE 2:** quando o vídeo subir no YouTube → colocar o link no `docs/RELATORIO_DE_ENTREGA.md` → regerar o PDF → enviar à FIAP. Badge Skills Boost: grupo ainda não tem (opcional).
3. ✅ **CLUSTER DERRUBADO em 2026-07-06** (após a gravação): `ingress-nginx` deletado (Load Balancer REMOVIDO — o endereço antigo morreu) e node group `workers` zerado (Min 0 / Desired 0 / Máx 4 — instâncias terminadas). Custo por hora ≈ zero. **Para religar no futuro:** node group → Edit → Desired 2 (e Min 1) → reinstalar o ingress-nginx (`kubectl apply` do manifesto oficial, provider AWS) → `kubectl apply -f infra/k8s/ingress.yaml` → o NOVO endereço do LB sai de `kubectl get svc ingress-nginx-controller -n ingress-nginx`. Os pods do togglemaster voltam sozinhos quando os nós subirem (o disco EBS do targeting foi preservado).

## A fazer (sem pressa)
- (vazio — P-006 concluída em 2026-07-06)

## Materiais prontos para a entrega
- `docs/ARQUITETURA.md` — arquitetura para leigos + diagrama Mermaid + decisões + 9 dificuldades.
- `docs/apresentacao/ToggleMaster_Fase2.pptx` — apresentação do projeto.
- Roteiro do vídeo — no chat de 2026-07-06 (e resumido no LOG).

## Achados (F-###)
- **F-001 — Inconsistência de região** (us-east-1 vs us-east-2). ✅ RESOLVIDO (commit 498f703).
- **F-002 — `GUIA-AWS.md` desatualizado** (3 RDS, us-east-1). ✅ RESOLVIDO em 2026-07-06 (P-006): guia atualizado para us-east-2, 2 RDS + targeting como pod, nós c7i-flex.large, seções de criação pelo console e de teardown reescritas.
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
