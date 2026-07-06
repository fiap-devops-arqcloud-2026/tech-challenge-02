# DECISÕES (ADR) — ToggleMaster Fase 2

> **TL;DR:** Decisões de arquitetura/processo com o PORQUÊ. Não reescrever decisões antigas — só mudar o Status ou adicionar nova.
>
> **Última atualização:** 2026-07-06 — Claude (Fable 5)

---

## D-001 — targeting_db roda como POD no EKS (não no RDS)
- **Contexto:** O projeto precisa de 3 bancos PostgreSQL (auth, flags, targeting). O Free Tier da AWS limita a conta a 2 instâncias RDS simultâneas; a 3ª falha com "maximum number of instances available with free plan accounts".
- **Decisão:** `auth_db` e `flags_db` ficam no RDS (já criados). `targeting_db` roda como um pod PostgreSQL dentro do cluster EKS (StatefulSet em `infra/k8s/postgres-targeting/`).
- **Alternativas consideradas:**
  - Compartilhar 1 RDS para flags_db + targeting_db — rejeitada (sem aprovação explícita; o PDF não cobre).
  - Todos os 3 bancos como pods — rejeitada (perderia a demonstração de RDS gerenciado e daria mais retrabalho).
  - Upgrade da conta AWS — rejeitada (custo).
  - AWS Academy — rejeitada (ver D-002).
- **Status:** ✅ Aprovada pelo professor em 2026-06. Manifestos criados (commit 5d6c008).

## D-002 — Permanecer na conta pessoal Free Tier (não usar AWS Academy)
- **Contexto:** Um professor sugeriu o AWS Academy por não ter limite de instâncias RDS.
- **Decisão:** Continuar na conta pessoal.
- **Por quê:** O Academy é travado nas regiões us-east-1/us-west-2 (toda a infra está em us-east-2 — seria refazer tudo); usa credenciais TEMPORÁRIAS (expiram ~4h, quebrariam os secrets de SQS no meio da gravação); e tem IAM restrito (risco no eksctl/EKS). O professor não garantiu IAM/EKS no Academy.
- **Status:** ✅ Decidida.

## D-003 — Região us-east-2 (Ohio)
- **Contexto:** O plano inicial citava us-east-1 (N. Virginia).
- **Decisão:** Toda a infra em us-east-2 (Ohio).
- **Status:** ✅ Decidida. Manifestos corrigidos (commit 498f703). `GUIA-AWS.md` ainda precisa ser atualizado (P-006).

## D-004 — Demais dependências como serviços gerenciados/serverless
- **Decisão:** Redis = ElastiCache; fila = SQS; analytics = DynamoDB. Só o targeting é pod.
- **Por quê:** SQS e DynamoDB não custam nada parados; assim sobe-se só o EKS na hora da demo, simplificando custo e operação.
- **Status:** ✅ Decidida e **concluída** — DynamoDB, SQS e ElastiCache criados em 2026-06-25.

## D-005 — Versionar a pasta 00_COLAB_IA no Git (sincronizar entre 2 máquinas)
- **Contexto:** Gabriel usa 2 notebooks (trabalho + pessoal) e quer continuar o projeto em ambos sem retrabalho. O código já sincroniza via GitHub, mas a `00_COLAB_IA/` estava no `.gitignore` (só local) e a memória interna do Claude não sincroniza entre máquinas.
- **Decisão:** Tirar a `00_COLAB_IA/` do `.gitignore` e versioná-la; criar um `CLAUDE.md` na raiz (lido automaticamente pelo Claude Code) apontando para ela. Reverte a decisão temporária de 2026-06-25 de mantê-la fora do Git.
- **Por quê:** O repo é **privado** (`fiap-devops-arqcloud-2026/tech-challenge-02`), então não há exposição. Assim, um único `git pull`/`push` sincroniza código + contexto entre os dois notebooks, e o contexto também fica disponível para o Codex.
- **Alternativas:** sincronizar via OneDrive/Drive (mais frágil, conflita com o Git) ou repo separado (overkill) — rejeitadas.
- **Status:** ✅ Decidida e aplicada em 2026-06-28.

## D-006 — Entrega mínima da FIAP: 1 réplica por serviço + HPA enxuto + node group t3.medium
- **Contexto:** Gabriel quer entregar exatamente o que o PDF da FIAP exige, "nada a mais — o básico e simples bem feito". O PDF (págs. 5 e 8) só obriga, sobre escalabilidade: (a) node group com auto scaling (ex.: Mínimo=1, Desejado=2, Máximo=4) e (b) **HPA por CPU em `evaluation-service` e `analytics-service`**. NÃO exige número de réplicas dos serviços, nem KEDA (KEDA é explicitamente "(Opcional) – Recomendado", não obrigatório).
- **Decisão:**
  - Todos os 5 serviços com `replicas: 1` (auth/flag/targeting/evaluation/analytics). Sem réplica extra de alta disponibilidade.
  - HPA só em `evaluation` e `analytics`, com `min 1 / max 2` (sobem de 1→2 sob carga — suficiente para demonstrar a escalabilidade no vídeo).
  - Sem KEDA (opcional → pulado).
  - Node group: **2× t3.medium**, Min 1 / Desejado 2 / Máx 4.
- **Por quê / alternativas:**
  - `t3.micro` (Free Tier) é **inviável**: limite de ~4 pods por nó (consumidos pelos DaemonSets de sistema: aws-node, kube-proxy, pod-identity, node-monitoring) + só 1 GB de RAM. Descartada.
  - 1 nó só (mesmo t3.medium): o HPA não teria onde colocar os pods novos da escalabilidade → ficariam "Pending" e a demonstração falharia. Por isso Desejado = 2 (a 2ª máquina é o "lugar" pros pods escalados).
  - Manter 2 réplicas em auth/flag/targeting era só HA (escolha nossa), não exigência → reduzido a 1 para enxugar.
  - Custo do node group ~US$ 0,08/h; ligar só na demo e derrubar depois (a economia de Free Tier não compensa o risco de a demo falhar).
- **Status:** ✅ Decidida e **aplicada nos manifestos** em 2026-06-29 (4 deployments `replicas:1` + 2 HPAs `min1/max2`). Node group criado em 2026-07-06 — mas com c7i-flex.large, não t3.medium (ver D-007).

## D-007 — Node group com c7i-flex.large (o plano gratuito bloqueou a t3.medium)
- **Contexto:** Ao criar o node group `workers` com t3.medium (2026-07-06), o EC2 recusou o lançamento: "The specified instance type is not eligible for Free Tier". A conta está no **plano gratuito novo da AWS**, que só permite lançar instâncias elegíveis ao Free Tier.
- **Decisão:** Usar **c7i-flex.large** (2 vCPU, 4 GB — equivalente direto da t3.medium, ~US$ 0,085/h), mantendo Min 1 / Desejado 2 / Máx 4.
- **Alternativas:** t3.small/micro (RAM/pods insuficientes — mesmo motivo de D-006); t4g (ARM — as imagens Docker são x86); m7i-flex.large (8 GB, mais cara — desnecessária); upgrade da conta para plano pago (evitável).
- **Status:** ✅ Aplicada em 2026-07-06. Node group `workers` Active com 2× c7i-flex.large.
