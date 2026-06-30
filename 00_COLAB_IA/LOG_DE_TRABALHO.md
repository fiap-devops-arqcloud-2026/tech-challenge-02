# LOG DE TRABALHO — append-only (entrada nova no TOPO)

> **TL;DR:** Diário de sessões. Nunca apagar/reescrever entradas antigas — só acrescentar no topo. A cada ~5 entradas, resumir as antigas no DOSSIE e manter só as 5 recentes aqui.
>
> **Última atualização:** 2026-06-29 — Claude (Opus 4.8)

---

## 2026-06-29 — Claude (Opus 4.8) — Rede validada, IAM roles, cluster EKS criado + manifestos enxugados (entrega mínima)

**Feito (via console AWS, Gabriel clicando passo a passo):**
- **Rede (F-003) RESOLVIDO.** Auditamos TODAS as sub-redes e descobrimos que o VPC `vpc-03a557849629939d0` JÁ tinha 4 sub-redes em 2 AZs (o dossiê antigo dizia "só us-east-2a"). Mapa real:
  - Públicas: `subnet-020ef26c5b392069e` (2a, 10.0.10.0/24) e `subnet-042a13d25a15bc975` (2b, 10.0.20.0/24) — ambas na route table pública `rtb-01248b4b82a5ce677` (rota `0.0.0.0/0 → igw-0364461e4d4226f8b` CONFIRMADA; auto-assign public IPv4 = Yes).
  - Privadas: `subnet-061bdfce861d99204` (2a, 10.0.11.0/24) e `subnet-0e1a51660acf2b025` (2b, 10.0.12.0/24).
  - Adicionada a tag `kubernetes.io/role/elb=1` nas 2 públicas (pré-requisito do Load Balancer do Nginx).
- **IAM roles criadas** (conta pessoal, sem LabRole): `togglemaster-eks-cluster-role` (AmazonEKSClusterPolicy) e `togglemaster-eks-node-role` (AmazonEKSWorkerNodePolicy + AmazonEC2ContainerRegistryReadOnly + AmazonEKS_CNI_Policy).
- **Cluster EKS `togglemaster-cluster` CRIADO e Active** (pelo console, NÃO eksctl): K8s 1.30, endpoint Public and private, control plane nas 2 sub-redes públicas, sem scaling tier, sem Auto Mode, Bootstrap admin = Allow.
  - Add-ons: CoreDNS, kube-proxy, Amazon VPC CNI, EKS Pod Identity Agent, Node monitoring agent e **Metrics Server** (community add-on — já cumpre o pré-requisito do HPA; não precisa mais instalar via kubectl).
  - Observability/logs do control plane: tudo DESLIGADO (evita custo CloudWatch).
- **Manifestos enxugados (D-006, "entrega mínima FIAP"):** os 5 serviços com `replicas: 1`; HPA de evaluation e analytics de `min/max` antigos para `min 1 / max 2`. Só evaluation e analytics escalam (1→2), que é o que o PDF exige.

**Decisão de máquina (a executar amanhã):** node group `workers` **2× t3.medium**, Min 1 / Desejado 2 / Máx 4. Motivo: t3.micro (Free Tier) é inviável (limite ~4 pods/nó + 1 GB RAM); 1 nó só não deixa o HPA escalar (pods ficariam Pending). Custo ~US$0,08/h, ligado só na demo. Ver D-006.

**Descobertas:**
- **F-003 RESOLVIDO** (VPC já tinha 2 AZs; dossiê estava incompleto — corrigido no DOSSIE §4).
- A **chave IAM de deploy NÃO está mais pendente**: já configurada via `aws configure` e validada (ver memória privada `credenciais-deploy-aws`). Logo, as etapas de kubectl de amanhã NÃO estão bloqueadas.

**Arquivos:** `infra/k8s/{auth,flag,targeting,evaluation}-service/deployment.yaml` (replicas→1), `infra/k8s/{evaluation,analytics}-service/hpa.yaml` (min1/max2), `00_COLAB_IA/{PENDENCIAS,DOSSIE,DECISOES,LOG}` (este update + D-006).

**Estado p/ amanhã (próximo passo):**
- **Cluster Active.** Próxima tarefa = **criar o node group** (2× t3.medium, Min1/Des2/Máx4) pelo console: aba Compute → Add node group → Node IAM role `togglemaster-eks-node-role` → sub-redes = as 2 públicas.
- Depois, na ordem: **EBS CSI Driver** (add-on, criar role via Pod Identity) → **Nginx Ingress Controller** (Helm/kubectl) → `aws eks update-kubeconfig` → preencher secrets (valores na memória privada) → `kubectl apply -f infra/k8s/...` → vídeo → relatório.
- **Metrics Server JÁ instalado** (add-on) — pular o `kubectl apply` do metrics-server.

---

## 2026-06-28 — Claude (Opus 4.8) — Sincronização entre 2 notebooks + auditoria das docs

**Feito:**
- Recap: o **ElastiCache (P-003) foi concluído em 2026-06-25** — cluster `togglemaster-redis` (Redis OSS 7.1, cache.t3.micro, sub-rede privada), endpoint no `evaluation-service/configmap.yaml` (commit 7081e5a), regra 6379 adicionada no SG `sg-0e79721741070ef64`.
- Gabriel trabalha em **2 notebooks** (trabalho + pessoal) e quer continuidade. Como o repo é **privado**, passamos a **versionar a `00_COLAB_IA/`** (saiu do `.gitignore`) → código + contexto sincronizam via `git pull`/`push`. (D-005.)
- Criado o **`CLAUDE.md` na raiz** (versionado): o Claude Code lê automaticamente ao abrir a pasta → aponta para a `00_COLAB_IA/` e resume as regras → continuidade automática em qualquer máquina.
- **Auditoria das docs:** corrigidas desatualizações (várias diziam "próxima tarefa = ElastiCache", já feito; notas de "pasta fora do Git" trocadas por "versionada/sincroniza via Git").
- Adicionado o comando completo do `eksctl create cluster` em PENDENCIAS (P-004) e um aviso de "desatualizado" no topo do `GUIA-AWS.md`.

**Descobertas:** ⚠️ **F-003** — o EKS exige sub-redes em ≥2 AZs, mas o VPC só tem sub-redes em **us-east-2a**. Precisa criar uma sub-rede pública em **us-east-2b** ANTES de criar o cluster (documentado em P-004).

**Decisões/Por quê:** D-005 (versionar a `00_COLAB_IA/` no repo privado para sincronizar entre máquinas).

**Arquivos:** `.gitignore` (remove 00_COLAB_IA), `CLAUDE.md` (novo, raiz), `00_COLAB_IA/*` (atualizados), `GUIA-AWS.md` (banner de desatualizado).

**Estado p/ o próximo agente (qualquer máquina):**
- **TODA a infra gerenciada está pronta:** RDS auth+flags, DynamoDB, SQS, ElastiCache. Manifestos K8s prontos (inclui pod targeting).
- **Próxima tarefa = criar o cluster EKS (P-004)** — passo "dia da gravação". ANTES: criar sub-rede pública em us-east-2b (F-003). Comando do eksctl + ordem dos add-ons (EBS CSI → Metrics → Nginx) em PENDENCIAS.
- Depois: preencher secrets (checklist em PENDENCIAS) → deploy → vídeo → relatório.
- Senha dos bancos e credenciais AWS NÃO versionadas — pedir ao Gabriel.
- Branch `dev`. Sincronizar entre notebooks: `git push` aqui, `git pull` no outro.

---

## 2026-06-25 — Claude (Opus 4.8) — Região, pod do targeting, serverless e pasta de colaboração

**Feito:**
- Analisei o estado do projeto (manifestos, infra, pendências).
- Corrigi a região us-east-1 → us-east-2 em 8 manifestos de `infra/k8s/` (commit 498f703).
- Criei os manifestos do banco targeting como pod em `infra/k8s/postgres-targeting/` (commit 5d6c008).
- Preparei o comando completo do EBS CSI Driver (3 passos, com a role IAM) — salvo em PENDENCIAS.
- Criei (com o Gabriel, via console) a tabela **DynamoDB `ToggleMasterAnalytics`** e a fila **SQS `togglemaster-events`** em us-east-2 (P-001 e P-002).
- Montei a pasta `00_COLAB_IA/` — naquela data, decisão de ficar fora do Git (revertida em 2026-06-28, ver D-005).

**Decisões/Por quê:** D-001 (targeting como pod) · D-002 (não Academy) · D-003 (us-east-2) · D-004 (ElastiCache/SQS/DynamoDB gerenciados).

**Descobertas:** F-001 (região — resolvido) · F-002 (`GUIA-AWS.md` desatualizado, vira P-006).
