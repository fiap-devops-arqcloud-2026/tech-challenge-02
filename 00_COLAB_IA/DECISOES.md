# DECISÕES (ADR) — ToggleMaster Fase 2

> **TL;DR:** Decisões de arquitetura/processo com o PORQUÊ. Não reescrever decisões antigas — só mudar o Status ou adicionar nova.
>
> **Última atualização:** 2026-06-28 19:52 (BRT) — Claude (Opus 4.8)

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
