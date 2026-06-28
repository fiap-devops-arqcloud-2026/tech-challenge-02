# CLAUDE.md — ToggleMaster (Tech Challenge Fase 2, FIAP)

> Este arquivo é lido **automaticamente** pelo Claude Code ao abrir o projeto (e serve de guia para o Codex).
> Ele aponta para o contexto completo e resume as regras essenciais — funciona em qualquer máquina.

## ⚡ Comece por aqui (qualquer notebook)
1. `git pull` (pegar a última versão).
2. **Leia a pasta `00_COLAB_IA/`** antes de trabalhar, nesta ordem:
   - `00_COLAB_IA/LEIA-PRIMEIRO.md` — protocolo de colaboração
   - `00_COLAB_IA/PENDENCIAS_E_PROXIMOS_PASSOS.md` — o que falta (próxima tarefa no topo)
   - topo do `00_COLAB_IA/LOG_DE_TRABALHO.md` — o que o último agente fez
   - `00_COLAB_IA/DOSSIE_CONTEXTO.md` + `DECISOES.md` — verdade estável e decisões

## 🧭 O projeto em 30 segundos
- **ToggleMaster:** sistema de feature flags, 5 microsserviços, indo para **AWS EKS**.
- **Ambiente:** conta pessoal AWS, Free Tier, região **us-east-2 (Ohio)**, Account `891376952395`.
- **Bancos:** `auth_db` e `flags_db` no RDS; `targeting_db` como **pod** no EKS (`infra/k8s/postgres-targeting/`).
- **Estado (2026-06-28):** toda a infra gerenciada criada (RDS, DynamoDB, SQS, ElastiCache). **Próxima tarefa: criar o cluster EKS** (PENDENCIAS P-004) — ⚠️ exige criar antes uma sub-rede em us-east-2b (só há AZ us-east-2a).
- IDs reais da AWS: `00_COLAB_IA/DOSSIE_CONTEXTO.md` §4.

## 📌 Regras de trabalho (do Gabriel)
- Idioma **pt-BR**; explicar simples primeiro, depois técnico; conciso. Gabriel **não** é técnico da área.
- **Comentar todas as linhas de código** (documentação).
- Commits: **Conventional Commits**, com título E descrição detalhada. Pode commitar direto na branch `dev`.
- **Um passo de cada vez**; confirmar a conclusão antes de avançar. Nunca inventar; marcar [INCERTO] e perguntar.
- Datas absolutas (ISO). Ao terminar a sessão: **atualizar a `00_COLAB_IA/`** (LOG no topo, PENDENCIAS, DECISOES) e dar `git push`.

## 💻 Sincronização entre 2 notebooks
O repo do GitHub é **privado** e a `00_COLAB_IA/` é **versionada** — código e contexto viajam juntos (D-005).
- Ao começar numa máquina: `git pull`.
- Ao terminar: `git push`.
- Segredos (senha dos bancos, credenciais AWS) **não** são versionados — pedir ao Gabriel.

## ⚠️ Cuidados
- Nunca commitar segredos (os secrets têm placeholders; preencher só no deploy).
- Região SEMPRE `us-east-2` e Account `891376952395`.
- `GUIA-AWS.md` está **desatualizado** (descreve 3 RDS/us-east-1) — confie na `00_COLAB_IA/`, não nele (P-006).
