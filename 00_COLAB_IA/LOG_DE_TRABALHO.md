# LOG DE TRABALHO — append-only (entrada nova no TOPO)

> **TL;DR:** Diário de sessões. Nunca apagar/reescrever entradas antigas — só acrescentar no topo. A cada ~5 entradas, resumir as antigas no DOSSIE e manter só as 5 recentes aqui.
>
> **Última atualização:** 2026-07-08 — Claude (Fable 5)

---

## 2026-07-08 — Claude (Fable 5) — Consistência das docs de replicação (secrets já scrubados pelo Codex)

**Contexto:** Gabriel pediu para scrubar secrets/.env e deixar a doc de replicação clara para o repo PÚBLICO. Ao verificar, o **Codex já tinha feito o scrub** (commit `2ebe9af`): `.env` fora do Git e ignorado; `.env.example` limpo; os 6 `secret.yaml` convertidos de base64 para `stringData` com placeholders `REPLACE_WITH_...`; binário `auth-service.exe` removido. Chave IAM revogada + RDS excluídos pelo Gabriel → segredos antigos no histórico estão INERTES. (Codex registrou P-009: excluir a chave IAM em definitivo antes de publicar.)

**Feito nesta sessão (só documentação — o código de secrets já estava certo):**
- **GUIA-AWS.md §11/§12 corrigido:** instruíam gerar **Base64**, mas os secrets agora usam `stringData` (texto puro) — encodar em base64 quebraria a senha. Reescrito para texto puro; tabela corrigida (targeting = pod `postgres-targeting:5432`; adicionada a linha do `postgres-targeting/secret.yaml`); §11.3 ganhou o apply do `postgres-targeting/`; §12 sem o passo de base64.
- **README.md:** nova subseção "Configuração dos secrets (antes do deploy)" (tabela placeholder→valor, nota de `stringData` sem base64) + "Último passo: criar a SERVICE_API_KEY de produção" fechando o fluxo de replicação na nuvem.
- Memória privada `repo-tratado-como-laboratorio` atualizada (repo agora PÚBLICO com placeholders — não re-adicionar segredos reais).

**Estado:** entrega segue igual (falta só o link do YouTube no relatório). Docs de replicação consistentes local + nuvem. Verificar com Codex o P-009 (exclusão definitiva da chave IAM) antes de tornar público.

---

## 2026-07-08 13:48 (BRT) — Codex — PR dev → main aberto

**Feito:** aberto o Pull Request rascunho **#3**, da branch `dev` para `main`:
`https://github.com/fiap-devops-arqcloud-2026/tech-challenge-02/pull/3`.

**Decisões/Por quê:** PR criado como rascunho para permitir revisão antes do merge. O PR
centraliza a comparação, a discussão, as validações e o histórico da aprovação.

**Arquivos:** `00_COLAB_IA/LOG_DE_TRABALHO.md` (registro de handoff).

**Descobertas:** GitHub classificou o PR como `MERGEABLE`; nenhuma verificação automática
obrigatória apareceu configurada. O conector retornou 404 no repo privado, então a criação
foi concluída pelo `gh` autenticado, conforme fallback previsto.

**Estado p/ o próximo agente:** PR #3 aberto em rascunho. Próximos passos humanos: revisar
o diff, marcar como pronto e fazer o merge em `main` quando aprovado. P-009 continua aberto
para exclusão definitiva da chave IAM antes de tornar o repositório público.

## 2026-07-08 13:45 (BRT) — Codex — Publicação concluída na branch dev

**Feito:** commit principal `2ebe9af` criado e enviado para `origin/dev`, contendo todo o
escopo autorizado: saneamento das credenciais atuais, README reproduzível, Secrets com
placeholders, remoção do `.env` versionado, remoção do executável, `AGENTS.md` e PDF de teste.

**Decisões/Por quê:** não foi aberto PR automaticamente. A branch remota padrão é `dev`;
`main` e `dev` estão divergentes, mas a simulação de merge terminou sem conflitos.

**Arquivos:** publicação de todos os arquivos listados nas entradas anteriores.

**Descobertas:** após o push, `dev` estava 21 commits à frente e 3 atrás de `main`. Não
havia PR aberto `dev → main` e a proteção de branch não estava disponível no repositório
privado atual.

**Estado p/ o próximo agente:** alterações publicadas em `dev`. Próxima decisão humana:
abrir PR `dev → main` para revisão e merge; depois, excluir definitivamente a chave IAM
desativada antes de tornar o repositório público (P-009).

## 2026-07-08 13:43 (BRT) — Codex — Chave IAM desativada + publicação solicitada

**Feito:** Gabriel confirmou que a chave IAM antiga foi desativada, mas ainda não excluída.
Revisado o estado Git completo para commit e push da branch `dev`, incluindo os arquivos
adicionados pelo usuário (`AGENTS.md` e o PDF de teste do relatório).

**Decisões/Por quê:** publicar primeiro em `dev`. A branch padrão atual é `dev`; um PR
`dev → main` é recomendado antes do merge porque as branches possuem históricos divergentes.

**Arquivos:** todo o escopo já registrado nas entradas anteriores, mais a confirmação em
`PENDENCIAS_E_PROXIMOS_PASSOS.md`.

**Descobertas:** `main` possui 3 commits ausentes em `dev`, enquanto `dev` possui 20
commits ausentes em `main`. Não há PR aberto de `dev` para `main`.

**Estado p/ o próximo agente:** commit e push autorizados para `dev`. PR/merge em `main`
não autorizado nesta etapa; aguardar decisão do Gabriel após o push.

## 2026-07-08 13:36 (BRT) — Codex — Binário removido + PostgreSQL esclarecido

**Feito:** removido `services/auth-service/auth-service.exe` (artefato local de build,
desnecessário para Docker/EKS) e adicionada a regra `*.exe` ao `.gitignore`. O README agora
explica que o Compose sobe 2 containers PostgreSQL, mas eles hospedam 3 bancos lógicos:
`auth_db`, `flags_db` e `targeting_db`.

**Decisões/Por quê:** nenhuma decisão arquitetural nova. O arranjo local continua atendendo
ao enunciado: 2 instâncias/containers PostgreSQL; a separação lógica mantém 3 bancos.

**Arquivos:** `.gitignore`, `README.md`, `services/auth-service/auth-service.exe` (removido)
e `00_COLAB_IA/LOG_DE_TRABALHO.md`.

**Descobertas:** o binário não participava do build Docker; cada Dockerfile Go recompila o
serviço para Linux. A aparente diferença de “2 versus 3 bancos” era apenas terminológica.

**Estado p/ o próximo agente:** alteração concluída; manter P-009 como próximo passo externo
(excluir definitivamente a chave IAM antiga antes de publicar).

## 2026-07-08 13:20 (BRT) — Codex — README reproduzível + credenciais atuais removidas

**Feito:**
- Reproduzido o problema em ambiente limpo: 9 containers saudáveis, mas `/evaluate`
  retornava HTTP 502 porque a `SERVICE_API_KEY` antiga não existia no banco novo.
- README atualizado com o processo correto: copiar `.env.example`, subir o Compose,
  criar uma chave no `auth-service`, preencher o `.env`, recriar o
  `evaluation-service` e testar flag/regra/avaliação/cache.
- Documentado que o SQS e o worker do analytics ficam desativados localmente; o fluxo
  SQS→DynamoDB é demonstrado apenas na AWS.
- `.env` removido do controle do Git sem apagar a cópia local e incluído no
  `.gitignore`. `.env.example` ficou somente com valores locais e chave inicialmente vazia.
- Os 6 `infra/k8s/*/secret.yaml` foram convertidos para modelos `stringData` com placeholders.
- Valores de credenciais foram redigidos do LOG/PENDENCIAS e a política pública foi
  espelhada em README, CLAUDE/AGENTS, DOSSIE, DECISOES e documentos de organização.

**Decisões/Por quê:** D-008 — preparar o estado atual para publicação sem reescrever o
histórico, conforme decisão do Gabriel. Credenciais recuperáveis em commits antigos nunca
podem ser reutilizadas; a chave IAM antiga deve ser desativada antes de publicar (P-009).

**Arquivos:** `.gitignore`, `.env.example`, `README.md`, `CLAUDE.md`, `AGENTS.md`,
`services/{auth-service,flag-service,evaluation-service}/README.md`, `infra/k8s/*/secret.yaml`,
`docs/ARQUITETURA.md` e `00_COLAB_IA/*`.

**Descobertas:** padrões de credenciais reais no estado atual versionável = 0. Manifestos
Secret passaram em `kubectl create --dry-run=client`. Teste limpo final: 9 containers,
5 health checks HTTP 200, chave criada, flag/regra criadas, avaliação `result:true` e
dois registros confirmando SQS desativado. Os RDS de laboratório já haviam sido excluídos,
conforme informado pelo Gabriel.

**Estado p/ o próximo agente:** saneamento local concluído. Próximo passo obrigatório =
Gabriel desativar/excluir a chave IAM antiga no console AWS (P-009); depois revisar o diff,
commitar e publicar apenas quando solicitado. O histórico não foi limpo por decisão explícita.

## 2026-07-06 (noite, 3ª parte) — Claude (Fable 5) — CLUSTER DERRUBADO + RMs oficiais + rascunho do relatório + roteiro versionado

**Feito:**
- **Cluster DERRUBADO** (Gabriel confirmou o fim da gravação): namespace `ingress-nginx` deletado (LB removido — endereço antigo morreu) e node group `workers` zerado (Min 0/Des 0/Máx 4). Ficaram de pé (custo ~zero parados): control plane, RDS ×2, ElastiCache, SQS, DynamoDB, ECR e o PVC/EBS do targeting. Instruções de religar em PENDENCIAS.
- **RMs oficiais encontrados** no relatório da Fase 1 (`tech-challenge-01/FIAP - Tech Challenge – Fase 1 – Grupo 203.pdf`) e aplicados no README. [INCERTO] "Felipe Brito" (@Durmiand) = João Carlos da Silva Brito? Aguardando confirmação do Gabriel.
- **Rascunho do relatório da Fase 2** criado em `docs/RELATORIO_DE_ENTREGA.md` — falta só: Discord dos 5, link do YouTube e a confirmação acima (+ badge Skills Boost opcional).
- **Roteiro do vídeo versionado** em `docs/ROTEIRO_VIDEO.md` (com narrações e porquês — regra "X com Y porque Z" do feedback da Fase 1). Feedback da Fase 1 (nota 76,5) salvo na memória privada do Claude.

**Estado p/ o próximo agente:** entrega quase fechada — falta YouTube + dados do Discord + gerar o PDF do relatório. Infra AWS dormindo, não gastando.

---

## 2026-07-06 (noite, 2ª parte) — Claude (Fable 5) — Revisão de comentários do código + README/GUIA-AWS/CLAUDE.md atualizados (P-006 ✅)

**Feito:**
- **Revisão de comentários em TODO o código** (regra do Gabriel: tudo comentado):
  - `evaluation-service/evaluator.go`: removidos comentários de rascunho ("<--- ADICIONE ESTA LINHA" etc.); comentadas as funções `fetchRule`, `getDeterministicBucket` e os 3 degraus da `runEvaluationLogic`; explicado o porquê do CACHE_TTL de 30s.
  - `evaluation-service/handlers.go`: comentários de propósito em `EvaluationResponse`, `healthHandler` e `evaluationHandler` (hot path).
  - `auth-service/{main,handlers,key}.go`: imports mortos comentados substituídos por explicações reais (driver pgx via `_`, uso do crypto etc.).
  - 3 serviços Python: docstring nos `health()`. Dockerfiles, SQLs, manifestos e docker-compose JÁ estavam bem comentados (auditados, sem mudança).
- **README.md atualizado:** targeting agora documentado como pod (com o porquê), tabela de infra 2 RDS + 1 pod, seção de deploy com região/cluster corretos (us-east-2, `togglemaster-cluster`), passo do postgres-targeting no kubectl apply, nota sobre secrets versionados (repo-laboratório), árvore de pastas com docs/ e postgres-targeting/.
- **P-006 ✅ — GUIA-AWS.md atualizado:** us-east-2 em todo o arquivo; seção RDS reescrita (2 instâncias + pod do targeting); seção do cluster reescrita com o passo a passo REAL pelo console (control plane + node group c7i-flex.large + EBS CSI/gp2 default) mantendo eksctl como alternativa; teardown reescrito (LB + node group primeiro; RDS targeting removido). F-002 RESOLVIDO.
- **CLAUDE.md atualizado:** estado real (deploy completo, vídeo gravado), política de segredos do repo-laboratório, aviso do GUIA-AWS trocado.

**Estado p/ o próximo agente:** igual à entrada anterior — falta YouTube + relatório (P-008) e decidir derrubar o cluster.

---

## 2026-07-06 (noite) — Claude (Fable 5) — VÍDEO GRAVADO 🎥 + docs de arquitetura + apresentação PPTX

**Feito:**
- **P-007 — Gabriel GRAVOU o vídeo da demo** (roteiro completo: local com docker compose, infra na nuvem, ingress, escalabilidade do evaluation e do analytics, DynamoDB e explicações da Parte 6). Falta: subir no YouTube e colocar o link no relatório.
- **Criado `docs/ARQUITETURA.md`:** arquitetura explicada para leigos + diagrama Mermaid completo + as 7 decisões (D-001..D-007) + as 9 dificuldades enfrentadas com soluções + tabela de endpoints. É a fonte para o relatório e a apresentação.
- **Criada a apresentação `docs/apresentacao/ToggleMaster_Fase2.pptx`** (para leigos, com diagrama e dificuldades).
- Ambiente local havia sido validado mais cedo (9/9 healthy, ver adendo da entrada anterior).

**Estado p/ o próximo agente:**
- ⚠️ **Cluster ainda LIGADO** (2 nós c7i-flex.large + LB ≈ US$0,19/h). Gabriel gravou; **perguntar se já pode derrubar** (node group scale 0/delete + `kubectl delete ns ingress-nginx`).
- Falta: **subir o vídeo no YouTube** → **P-008 relatório** (.PDF/.txt: nomes + RM + Discord — faltam RMs de João Ciardullo, Douglas, Felipe Brito e João Gabriel — link do repo e link do vídeo) → P-006 (GUIA-AWS.md).

---

## 2026-07-06 — Claude (Fable 5) — DEPLOY COMPLETO: node group, EBS CSI, Nginx Ingress, secrets e aplicação no ar 🎉

**Feito (node group pelo console com Gabriel; resto via CLI pelo Claude):**
- **P-004b — Node group `workers` criado e Active.** ⚠️ t3.medium foi RECUSADA pelo plano gratuito novo da AWS ("not eligible for Free Tier") → trocamos para **c7i-flex.large** (2 vCPU/4 GB, ~US$0,085/h), Min 1 / Des 2 / Máx 4, AL2023, 20 GiB, nas 2 sub-redes públicas (D-007). 2 nós Ready.
- **P-004c — EBS CSI Driver** instalado (add-on via console, role via Pod Identity).
- **Permissões do `togglemaster-deploy`:** o usuário não tinha acesso EKS. Adicionada inline policy `eks-access` (`eks:*`) + **access entry** no cluster com `AmazonEKSClusterAdminPolicy`. `kubectl` conectado (`aws eks update-kubeconfig`).
- **P-004d — Nginx Ingress Controller v1.15.1** instalado (`kubectl apply`, provider AWS). LB público: `a4e86e3f9b5564375bcbe8c46ad4acee-fc7302f5c0e6e08e.elb.us-east-2.amazonaws.com`.
- **P-005 — Secrets preenchidos e DEPLOY FEITO.** Na execução original, os 6
  `secret.yaml` receberam valores do laboratório. Esses valores foram redigidos em
  2026-07-08 e não devem ser reutilizados; consultar D-008/P-009.
- **Consertos no caminho:**
  - StorageClass `gp2` não era default → PVC do targeting ficou Pending → marcada como default + PVC recriado.
  - SG `sg-06ca599ca5e54eb7d` (RDS) sem regra 5432 → liberado para 10.0.0.0/16.
  - Tabelas não existiam nos RDS → rodados `services/{auth,flag}-service/db/init.sql` via psql do pod postgres-targeting-0.
- **Verificação ponta a ponta (tudo OK):** 6 pods Running · `POST /flags` e `GET /evaluate` pelo LB público · evento SQS consumido pelo analytics · 1 item salvo no DynamoDB · HPAs lendo CPU (1–2%).

**Adendo (mesma sessão) — ambiente LOCAL validado para o vídeo:**
- `docker compose up` falhou na 1ª tentativa: o `infra/postgres-app/01-init-multi-db.sh` estava com **CRLF** (quebra de linha Windows) → `/bin/sh^M: bad interpreter` no contêiner → `targeting_db` não era criado. **Consertado:** script convertido para LF + regras `*.sh`/`*.sql text eol=lf` no `.gitattributes` (⚠️ na outra máquina, após o `git pull`, o arquivo já vem certo).
- Recriado do zero (`docker compose down -v && up -d`): **9/9 contêineres healthy**.
  Testado ponta a ponta local com uma chave de demonstração, flag `demo-local` criada e
  avaliada com `result:true`. A chave local deixou de valer quando o volume foi removido.
- Contêineres locais parados com `docker compose down` (SEM `-v` — os volumes ficam, então no dia do vídeo basta `docker compose up -d` que tudo volta funcionando).

**Estado p/ o próximo agente:**
- **Aplicação NO AR.** ⚠️ **Cluster LIGADO por decisão do Gabriel** (2 nós + LB ≈ US$0,19/h) para gravar o vídeo (P-007). Depois da gravação: derrubar node group (scale 0 ou delete) + `kubectl delete ns ingress-nginx`.
- Falta: **P-007 (vídeo)** — roteiro entregue ao Gabriel no chat de 2026-07-06 · **P-008 (relatório)** — faltam RMs de 4 integrantes · P-006 (GUIA-AWS.md desatualizado).

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
