# AGENTS.md — ToggleMaster (Tech Challenge Fase 2, FIAP)

> Este arquivo é lido **automaticamente** pelo Codex ao abrir o projeto (e serve de guia para o Codex).
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
- **Estado (2026-07-06):** ✅ **DEPLOY COMPLETO E VÍDEO GRAVADO** — cluster EKS + node group (2× c7i-flex.large) + aplicação no ar, verificada ponta a ponta. Falta: subir o vídeo no YouTube + relatório (P-008). ⚠️ O cluster pode estar LIGADO (~US$0,19/h) — conferir PENDENCIAS.
- IDs reais da AWS: `00_COLAB_IA/DOSSIE_CONTEXTO.md` §4. Arquitetura, decisões e dificuldades: `docs/ARQUITETURA.md`.

## 📌 Regras de trabalho (do Gabriel)
- Idioma **pt-BR**; explicar simples primeiro, depois técnico; conciso. Gabriel **não** é técnico da área.
- **Comentar todas as linhas de código** (documentação).
- Commits: **Conventional Commits**, com título E descrição detalhada. Pode commitar direto na branch `dev`.
- **Um passo de cada vez**; confirmar a conclusão antes de avançar. Nunca inventar; marcar [INCERTO] e perguntar.
- Datas absolutas (ISO). Ao terminar a sessão: **atualizar a `00_COLAB_IA/`** (LOG no topo, PENDENCIAS, DECISOES) e dar `git push`.

## 💻 Sincronização entre 2 notebooks
O repo do GitHub pode ser tornado **público para avaliação da FIAP**. A `00_COLAB_IA/`
continua versionada, mas nunca deve conter senhas, tokens ou credenciais reais (D-005/D-008).
- Ao começar numa máquina: `git pull`.
- Ao terminar: `git push`.

## ⚠️ Cuidados
- **Sobre segredos:** o `.env` é local e ignorado pelo Git. Os
  `infra/k8s/*/secret.yaml` versionados contêm somente placeholders; preencha os valores
  apenas na cópia local e nunca os envie ao Git.
- Região SEMPRE `us-east-2` e Account `891376952395`.
- `GUIA-AWS.md` foi **atualizado em 2026-07-06** (P-006 ✅): us-east-2, 2 RDS + targeting como pod, nós c7i-flex.large. Em caso de conflito, a `00_COLAB_IA/` é a fonte da verdade.
