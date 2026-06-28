# LOG DE TRABALHO — append-only (entrada nova no TOPO)

> **TL;DR:** Diário de sessões. Nunca apagar/reescrever entradas antigas — só acrescentar no topo. A cada ~5 entradas, resumir as antigas no DOSSIE e manter só as 5 recentes aqui.
>
> **Última atualização:** 2026-06-28 19:52 (BRT) — Claude (Opus 4.8)

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
