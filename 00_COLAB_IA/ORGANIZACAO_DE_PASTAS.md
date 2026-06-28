# ORGANIZAÇÃO DE PASTAS E NOMES

> **TL;DR:** Projeto de código adaptado (services/, infra/), mantendo esta pasta `00_COLAB_IA/` (versionada no Git) para a colaboração entre agentes e máquinas. Nomes em ISO, sem acentos problemáticos, sem espaços duplos.
>
> **Última atualização:** 2026-06-28 19:52 (BRT) — Claude (Opus 4.8)

## Estrutura atual do repositório
```
tech-challenge-02/
├── CLAUDE.md             (lido automaticamente pelo Claude Code; aponta para a 00_COLAB_IA)
├── 00_COLAB_IA/          (memória compartilhada entre agentes — VERSIONADA no Git)
├── services/             (código dos 5 microsserviços)
├── infra/
│   ├── k8s/              (manifestos Kubernetes, um subdiretório por serviço)
│   │   └── postgres-targeting/  (banco targeting como pod)
│   └── postgres-app/     (script de init do postgres local)
├── docker-compose.yaml   (ambiente local)
├── GUIA-AWS.md           (guia de deploy — desatualizado, ver P-006; tem aviso no topo)
└── README.md
```

## Convenção de nomes
- Datas em ISO: `AAAA-MM-DD`.
- Sem "Cópia", sem espaços duplos, sem acentos problemáticos em nomes de arquivo.
- Versões: `_v01`/`_v02` ou `_VIGENTE` (só uma vigente por vez).
- Versões antigas vão para `_ARQUIVO_MORTO/` (nunca excluir sem permissão).

## Observação importante
A pasta `00_COLAB_IA/` agora é **versionada no Git** (decisão D-005, 2026-06-28, repo privado). Sincroniza entre os 2 notebooks do Gabriel via `git pull`/`push`, junto com o código. Segredos (senhas, credenciais AWS) continuam FORA do Git.
