# LEIA-PRIMEIRO — Protocolo de colaboração entre agentes

> **TL;DR:** Esta pasta é a memória COMPARTILHADA entre os agentes de IA (Claude e Codex) e entre os 2 notebooks do Gabriel. Ao iniciar, dê `git pull` e leia nesta ordem: este arquivo → `PENDENCIAS` → topo do `LOG` → seção relevante do `DOSSIE`/`DECISOES`. Ao terminar, registre no `LOG`, atualize `PENDENCIAS`/`DECISOES` e dê `git push`. Nunca apague registro de outro agente — só acrescente.
>
> **Última atualização:** 2026-06-28 19:52 (BRT) — Claude (Opus 4.8)

## Por que esta pasta existe
O dono do projeto (Gabriel) alterna entre agentes (Claude e Codex) e entre 2 notebooks (trabalho + pessoal). O próximo agente/máquina precisa CONTINUAR sem retrabalho e sem reperguntar o que já se sabe. Por isso documentamos, datamos e organizamos aqui.

> ✅ **Esta pasta é VERSIONADA no Git** (repo privado — decisão D-005, 2026-06-28). Ela sincroniza entre as máquinas via `git pull`/`push`, junto com o código. (Até 2026-06-25 ficava fora do Git; isso mudou.)

## Ordem de leitura ao iniciar uma sessão
1. `git pull` (pegar a última versão)
2. `LEIA-PRIMEIRO.md` (este arquivo)
3. `PENDENCIAS_E_PROXIMOS_PASSOS.md` — o que falta fazer agora
4. Topo do `LOG_DE_TRABALHO.md` — o que o último agente fez
5. `DOSSIE_CONTEXTO.md` e `DECISOES.md` — verdade estável e decisões
6. Descobrir a data/hora atuais

## IDs cruzados
- `D-###` — Decisão (em `DECISOES.md`)
- `P-###` — Pendência (em `PENDENCIAS_E_PROXIMOS_PASSOS.md`)
- `F-###` — Achado/descoberta (em `PENDENCIAS_E_PROXIMOS_PASSOS.md`)

## Ritual de fim de sessão (obrigatório)
- Nova entrada no `LOG_DE_TRABALHO.md` (no TOPO, append-only)
- Atualizar `PENDENCIAS`
- Registrar novas `DECISOES`
- Atualizar `DOSSIE` se mudou algo estrutural
- `git push` (para o outro notebook receber)

## Conflito entre agentes
Se achar contradição, marque `⚠️ CONFLITO` no local, descreva as duas versões e pergunte ao Gabriel. Não corrija sozinho.

## Regra de ouro
Quem encerra deixa a pasta pronta (e dá push) para o outro agente/máquina assumir SEM reperguntar nada.

## Arquivos desta pasta
- `LEIA-PRIMEIRO.md` — este protocolo
- `DOSSIE_CONTEXTO.md` — verdade estável (fonte da verdade compartilhada)
- `DECISOES.md` — decisões com o porquê (ADR)
- `PENDENCIAS_E_PROXIMOS_PASSOS.md` — backlog e achados
- `LOG_DE_TRABALHO.md` — diário append-only
- `ORGANIZACAO_DE_PASTAS.md` — padrão de pastas e nomes
