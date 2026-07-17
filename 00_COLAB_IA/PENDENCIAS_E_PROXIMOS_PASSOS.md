# PENDÊNCIAS E PRÓXIMOS PASSOS

> **TL;DR:** Fase 2 ENTREGUE (deploy + vídeo `https://youtu.be/YpunNwLpf40` + relatório). Repo saneado e público.
> **Infra AWS TOTALMENTE EXCLUÍDA em 2026-07-09** (EKS, RDS auth+flags, ElastiCache, EBS órfão) — custo ~US$0.
> Chave IAM `togglemaster-deploy` revogada. Sobra só DynamoDB/SQS/ECR (Free Tier). Nada pendente de entrega.
>
> **Última atualização:** 2026-07-17 — Claude (Opus 4.8).

## Concluído

### 2026-07-06 — DEPLOY COMPLETO ✅
- ✅ **P-004b — Node group `workers`** (2× **c7i-flex.large** — t3.medium bloqueada pelo plano gratuito, ver D-007), Min 1/Des 2/Máx 4.
- ✅ **P-004c — EBS CSI Driver** (add-on, Pod Identity). StorageClass `gp2` marcada como default.
- ✅ **P-004d — Nginx Ingress v1.15.1**. LB: `a4e86e3f9b5564375bcbe8c46ad4acee-fc7302f5c0e6e08e.elb.us-east-2.amazonaws.com`.
- ✅ **kubectl conectado** (usuário `togglemaster-deploy` ganhou policy `eks:*` + access entry admin no cluster).
- ✅ **P-005 — Deploy de demonstração concluído.** Os valores usados naquela execução
  foram removidos do estado atual do repositório em 2026-07-08 e não devem ser reutilizados.
  Consertos históricos: SG do RDS (5432), `init.sql` do auth e do flags rodados nos RDS.
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
2. **P-008 — Relatório de entrega:** ✅ **CONCLUÍDO.** Vídeo publicado (`https://youtu.be/YpunNwLpf40`); link inserido no `docs/RELATORIO_DE_ENTREGA.md` e no PDF `docs/FIAP - Tech Challenge - Fase 2 - Grupo 203.pdf` (regerado). Obs.: o grupo tem também um `.docx` "Revisado" (mais completo) que é provavelmente o entregue de fato — decidir qual é o oficial. Badge Skills Boost: grupo não fez (opcional).
3. ✅ **CLUSTER DERRUBADO em 2026-07-06** (após a gravação): `ingress-nginx` deletado (Load Balancer REMOVIDO — o endereço antigo morreu) e node group `workers` zerado (Min 0 / Desired 0 / Máx 4 — instâncias terminadas). Custo por hora ≈ zero. **Para religar no futuro:** node group → Edit → Desired 2 (e Min 1) → reinstalar o ingress-nginx (`kubectl apply` do manifesto oficial, provider AWS) → `kubectl apply -f infra/k8s/ingress.yaml` → o NOVO endereço do LB sai de `kubectl get svc ingress-nginx-controller -n ingress-nginx`. Os pods do togglemaster voltam sozinhos quando os nós subirem (o disco EBS do targeting foi preservado).

## 🔴 Antes de tornar o repositório público (P-009)
1. ✅ **Chave IAM antiga desativada em 2026-07-08.** A exclusão definitiva continua
   recomendada antes de tornar o repositório público, pois uma chave apenas desativada pode
   ser reativada.
2. Confirmar que nenhum serviço futuro reutilizará credenciais recuperáveis no histórico Git.
3. Revisar o consentimento dos integrantes para exposição pública de nomes, RMs e Discords.
4. Fazer um clone limpo e repetir o roteiro local atualizado do README.

> **Risco aceito — D-008:** o histórico Git não será reescrito por decisão do Gabriel em
> 2026-07-08. Mesmo após o saneamento atual, commits antigos continuam contendo os valores
> anteriores. A publicação só é aceitável depois que a chave IAM antiga estiver inválida.

## A fazer (sem pressa)
- (vazio — P-006 concluída em 2026-07-06)

## Materiais prontos para a entrega
- `docs/ARQUITETURA.md` — arquitetura para leigos + diagrama Mermaid + decisões + 9 dificuldades.
- `docs/apresentacao/ToggleMaster_Fase2.pptx` — apresentação do projeto.
- Roteiro do vídeo — no chat de 2026-07-06 (e resumido no LOG).

## Material didático de apoio (2026-07-17 — não é entregável, é estudo)
- `docs/Material aulas/<1..6>/GUIA-ESTUDO-*.html` — **6 guias de estudo para leigos**, um por
  módulo do curso, explicando siglas/conceitos e ligando cada tema ao ToggleMaster. Commit `a7547ba`.
- `README.md` → seção "Recursos avançados do Kubernetes (referência para evolução)": tabela dos
  9 tópicos avançados com a coluna "Requisito p/ entrega" (obrigatório/opcional/desejável). Commit `a4e5042`.

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

## Checklist: Secrets para um eventual novo deploy
Todos os manifestos usam `stringData` com placeholders públicos. Preencha os valores
somente na cópia local e nunca comite o arquivo preenchido.
- `auth-service/secret.yaml` → nova `DATABASE_URL` e nova `MASTER_KEY`.
- `flag-service/secret.yaml` → nova `DATABASE_URL`.
- `targeting-service/secret.yaml` e `postgres-targeting/secret.yaml` → mesma senha nova.
- `evaluation-service/secret.yaml` → nova `SERVICE_API_KEY`, URL da nova fila SQS e
  credencial temporária ou IAM de menor privilégio.
- `analytics-service/secret.yaml` → mesma fila e credencial temporária ou IAM de menor privilégio.
- Preferência futura: IAM Role/Pod Identity em vez de chaves AWS estáticas.
