# DOSSIÊ DE CONTEXTO — ToggleMaster Fase 2 (fonte da verdade)

> **TL;DR:** 5 microsserviços (sistema de feature flags) indo para AWS EKS, conta pessoal Free Tier, região us-east-2. Bancos: auth + flags no RDS, targeting como pod no EKS. **Toda a infra gerenciada já criada (RDS, DynamoDB, SQS, ElastiCache); falta só o cluster EKS.** Trabalho de pós (FIAP), vale 90% da nota.
>
> **Última atualização:** 2026-06-28 19:52 (BRT) — Claude (Opus 4.8)

## 1. Objetivo
Migrar o monolito ToggleMaster (Fase 1) para 5 microsserviços conteinerizados rodando no Kubernetes (AWS EKS). Entregáveis: vídeo (até 20 min) mostrando local + nuvem + escalabilidade, e relatório com nomes/RMs/links. +10 pts extras com a trilha do Google Cloud Skills Boost.

## 2. Regras e preferências (do Gabriel)
- Idioma pt-BR; explicar simples primeiro, depois técnico; conciso.
- Comentar todas as linhas de código (documentação).
- Commits: Conventional Commits, com título E descrição detalhada.
- Pode commitar direto na branch `dev` (é a de desenvolvimento).
- Datas absolutas (ISO). Nunca inventar; marcar [INCERTO] e perguntar.
- Salvar memória ao longo das conversas; perguntar quando houver dúvida.
- Um passo de cada vez; confirmar a conclusão antes de avançar.
- Gabriel não é técnico da área — evitar jargão sem explicar.

## 3. Contexto
- Pós POSTECH/FIAP, Fase 2, trabalho em grupo. Vale 90% da nota.
- Aluno: Gabriel Tocaccelli, RM373763. Usa Claude e Codex alternadamente.
- Trabalha em **2 notebooks** (trabalho + pessoal); sincroniza tudo (código + esta pasta) via **Git** (repo privado). Ver D-005.
- Ambiente: conta pessoal AWS, Free Tier, região us-east-2 (Ohio), Account 891376952395.
- Repo: `github.com/fiap-devops-arqcloud-2026/tech-challenge-02` (privado), branch `dev`.

## 4. Arquivos e caminhos
- `CLAUDE.md` (raiz) — lido automaticamente pelo Claude Code; aponta para esta pasta e resume as regras.
- `docker-compose.yaml` — ambiente local (2 postgres, redis, dynamodb-local, 5 apps).
- `services/<svc>/` — código dos 5 microsserviços (+ `db/init.sql` de auth/flag/targeting).
- `infra/k8s/<svc>/` — manifestos K8s por serviço (deployment, service, configmap, secret; HPA em evaluation e analytics; ingress).
- `infra/k8s/postgres-targeting/` — banco targeting como pod (statefulset, service, configmap, secret).
- `infra/k8s/00-namespaces.yaml` — namespace `togglemaster`.
- `GUIA-AWS.md` — guia de deploy (DESATUALIZADO: 3 RDS/us-east-1; ver F-002/P-006 — tem aviso no topo).
- Memória privada do Claude (não compartilhada, NÃO sincroniza entre máquinas): `project_togglemaster.md` e afins.

### Infraestrutura AWS já criada (IDs reais)
- **Account ID:** 891376952395 · **Região:** us-east-2 (Ohio)
- **VPC:** `vpc-03a557849629939d0` (togglemaster-fiap-fase-02-vpc, 10.0.0.0/16)
- **Sub-rede pública:** `subnet-020ef26c5b392069e` (10.0.10.0/24, us-east-2a) — destino do EKS + Load Balancer
- **Sub-rede privada:** `subnet-061bdfce861d99204` (10.0.11.0/24, us-east-2a) — RDS + ElastiCache
- ⚠️ **Só há sub-redes em us-east-2a (1 AZ).** O EKS exige 2 AZs → criar uma sub-rede pública em us-east-2b antes do P-004.
- **Internet Gateway:** `igw-0364461e4d4226f8b`
- **ECR:** 5 repos em `891376952395.dkr.ecr.us-east-2.amazonaws.com/<svc>:latest` (auth/flag/targeting/evaluation/analytics-service). Backup DockerHub: `tocaccelli/<svc>:latest`
- **RDS `togglemaster-auth`** → `auth_db` (criado). **RDS `togglemaster-flags`** → `flags_db` (criado). Usuário: `toggle`. Senha: definida pelo Gabriel (não versionada).
- **SQS:** `togglemaster-events` — URL `https://sqs.us-east-2.amazonaws.com/891376952395/togglemaster-events`
- **DynamoDB:** `ToggleMasterAnalytics` (chave `event_id`)
- **ElastiCache:** `togglemaster-redis` — endpoint `togglemaster-redis.ewbn3x.ng.0001.use2.cache.amazonaws.com:6379` (Redis OSS 7.1, sub-rede privada, SG `sg-0e79721741070ef64` com 6379 liberado p/ 10.0.0.0/16). Já no `evaluation-service/configmap.yaml`.
- **Security group da camada de dados:** `sg-0e79721741070ef64` (libera 5432 do RDS e 6379 do Redis para os pods do EKS).
- **A criar:** cluster EKS `togglemaster-cluster` (P-004).

## 5. Processos
- Build/push: `docker compose build` → tag → push para ECR (us-east-2) e DockerHub (`tocaccelli/*`).
- Deploy: criar EKS → add-ons → preencher secrets/configmaps → `kubectl apply -f infra/k8s/...`.
- Custo: subir o EKS só na hora da demo e derrubar depois (control plane não é Free Tier). DynamoDB/SQS ~custo zero parados; ElastiCache + 2 RDS ficam ligados (derrubar após a entrega).
- Sincronizar entre notebooks: `git pull` ao começar, `git push` ao terminar.

## 6. Decisões
Ver `DECISOES.md`. Resumo: D-001 targeting como pod · D-002 não Academy · D-003 us-east-2 · D-004 ElastiCache/SQS/DynamoDB gerenciados · D-005 versionar a 00_COLAB_IA no Git (sync entre máquinas).

## 7. Pendências
Ver `PENDENCIAS_E_PROXIMOS_PASSOS.md`. **Próxima tarefa: criar o cluster EKS (P-004)** — atenção ao pré-requisito de 2 AZs.

## 8. Glossário
- **Feature flag:** interruptor que liga/desliga funcionalidade sem novo deploy.
- **EKS:** Kubernetes gerenciado da AWS. **ECR:** registro de imagens Docker.
- **RDS:** banco gerenciado. **ElastiCache:** Redis gerenciado. **SQS:** fila de mensagens. **DynamoDB:** banco NoSQL.
- **HPA:** auto-escala de pods por CPU. **StatefulSet:** workload com estado + disco (PVC). **AZ:** zona de disponibilidade (data center).

## 9. Cuidados
- Nunca commitar segredos. Os secrets têm placeholders; preencher só no deploy.
- Região SEMPRE us-east-2 e Account 891376952395 nos comandos.
- Free Tier: máx. 2 instâncias RDS. Por isso o targeting virou pod.
- AWS Academy tem credencial temporária (~4h) — não usar (D-002).
- EKS precisa de 2 AZs — o VPC só tem us-east-2a hoje (criar us-east-2b antes do P-004).
- Pasta `00_COLAB_IA/` agora é **versionada no Git** (repo privado) — sincroniza entre máquinas via `git pull`/`push`. Não vive mais só local.

## 10. Resumo das conversas
- **2026-06-25:** testes locais ok (vídeo gravado); infra AWS criada (IAM, ECR, VPC, 2 RDS); bateu o limite de RDS → targeting como pod (aprovado pelo professor); correção de região; manifestos do pod criados; pasta de colaboração montada; DynamoDB, SQS e ElastiCache criados.
- **2026-06-28:** decisão de sincronizar entre 2 notebooks → passamos a versionar a `00_COLAB_IA/` no Git e criamos o `CLAUDE.md` raiz; auditoria e correção das docs. Próximo: cluster EKS.

## 11. Memória interna (Claude) ↔ espelho
A memória privada do Claude (`project_togglemaster.md`) NÃO sincroniza entre máquinas nem é lida pelo Codex — esta pasta é a ponte. IDs da AWS e decisões estão duplicados aqui de propósito.

## 12. Instruções iniciais para o próximo assistente (qualquer máquina/agente)
1. `git pull`. Leia o `CLAUDE.md` da raiz → `LEIA-PRIMEIRO` → `PENDENCIAS` → topo do `LOG` → este DOSSIÊ + `DECISOES`.
2. Próxima tarefa concreta: criar o cluster EKS `togglemaster-cluster` (P-004) — ANTES, criar a sub-rede pública em us-east-2b (pré-requisito de 2 AZs). Detalhes em PENDENCIAS.
3. Trabalhe um passo de cada vez e confirme com o Gabriel antes de avançar.
4. Ao terminar: atualize esta pasta (LOG no topo, PENDENCIAS, DECISOES) e dê `git push`.
