# DOSSIÊ DE CONTEXTO — ToggleMaster Fase 2 (fonte da verdade)

> **TL;DR:** 5 microsserviços (sistema de feature flags) indo para AWS EKS, conta pessoal Free Tier, região us-east-2. Bancos: auth + flags no RDS, targeting como pod no EKS. **Toda a infra gerenciada criada; o control plane do cluster EKS já está criado e Active (2026-06-29).** Falta: node group + add-ons (EBS CSI, Nginx) + deploy + vídeo. Trabalho de pós (FIAP), vale 90% da nota.
>
> **Última atualização:** 2026-06-29 — Claude (Opus 4.8)

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
- **Entregar APENAS o mínimo que a FIAP exige, nada a mais — simples e bem feito** (ver D-006).

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
- `POSTECH - Tech Challenge - Fase 2.pdf` — enunciado oficial da FIAP (requisitos técnicos + entregáveis).
- Memória privada do Claude (não compartilhada, NÃO sincroniza entre máquinas): `project_togglemaster.md` e afins.

### Infraestrutura AWS já criada (IDs reais)
- **Account ID:** 891376952395 · **Região:** us-east-2 (Ohio)
- **VPC:** `vpc-03a557849629939d0` (togglemaster-fiap-fase-02-vpc, 10.0.0.0/16)
- **Sub-redes — 4, em 2 AZs (corrigido em 2026-06-29):**
  - **Públicas** (destino do EKS + Load Balancer): `subnet-020ef26c5b392069e` (10.0.10.0/24, us-east-2a) e `subnet-042a13d25a15bc975` (10.0.20.0/24, us-east-2b). Ambas na route table pública `rtb-01248b4b82a5ce677` (rota `0.0.0.0/0 → igw`; auto-assign public IPv4 = Yes; tag `kubernetes.io/role/elb=1`).
  - **Privadas** (RDS + ElastiCache): `subnet-061bdfce861d99204` (10.0.11.0/24, us-east-2a) e `subnet-0e1a51660acf2b025` (10.0.12.0/24, us-east-2b).
- **Internet Gateway:** `igw-0364461e4d4226f8b`
- **IAM roles do EKS (criadas 2026-06-29):** `togglemaster-eks-cluster-role` (`AmazonEKSClusterPolicy`) e `togglemaster-eks-node-role` (`AmazonEKSWorkerNodePolicy` + `AmazonEC2ContainerRegistryReadOnly` + `AmazonEKS_CNI_Policy`).
- **ECR:** 5 repos em `891376952395.dkr.ecr.us-east-2.amazonaws.com/<svc>:latest` (auth/flag/targeting/evaluation/analytics-service). Backup DockerHub: `tocaccelli/<svc>:latest`
- **RDS `togglemaster-auth`** → `auth_db`. **RDS `togglemaster-flags`** → `flags_db`. Usuário: `toggle`. Senha: definida pelo Gabriel (na memória privada; não versionada).
- **SQS:** `togglemaster-events` — URL `https://sqs.us-east-2.amazonaws.com/891376952395/togglemaster-events`
- **DynamoDB:** `ToggleMasterAnalytics` (chave `event_id`)
- **ElastiCache:** `togglemaster-redis` — endpoint `togglemaster-redis.ewbn3x.ng.0001.use2.cache.amazonaws.com:6379` (Redis OSS 7.1, sub-rede privada, SG `sg-0e79721741070ef64` com 6379 liberado p/ 10.0.0.0/16). Já no `evaluation-service/configmap.yaml`.
- **Security group da camada de dados:** `sg-0e79721741070ef64` (libera 5432 do RDS e 6379 do Redis para os pods do EKS).
- **EKS `togglemaster-cluster` (criado 2026-06-29, status Active):** pelo console (não eksctl). K8s 1.30, endpoint Public and private, control plane nas 2 sub-redes públicas, sem scaling tier, sem Auto Mode. Add-ons: CoreDNS, kube-proxy, Amazon VPC CNI, EKS Pod Identity Agent, Node monitoring agent, **Metrics Server** (community). Observability/logs desligados.
- **A criar:** node group (`workers`, 2× t3.medium, Min 1 / Desejado 2 / Máx 4), EBS CSI Driver, Nginx Ingress Controller; depois deploy dos manifestos.

## 5. Processos
- Build/push: `docker compose build` → tag → push para ECR (us-east-2) e DockerHub (`tocaccelli/*`).
- Deploy: criar EKS → node group → add-ons → conectar kubectl → preencher secrets/configmaps → `kubectl apply -f infra/k8s/...`.
- Custo: subir o EKS (control plane ~US$0,10/h) + node group (2× t3.medium ~US$0,08/h) só na hora da demo e derrubar depois. DynamoDB/SQS ~custo zero parados; ElastiCache + 2 RDS ficam ligados (derrubar após a entrega).
- Sincronizar entre notebooks: `git pull` ao começar, `git push` ao terminar.

## 6. Decisões
Ver `DECISOES.md`. Resumo: D-001 targeting como pod · D-002 não Academy · D-003 us-east-2 · D-004 ElastiCache/SQS/DynamoDB gerenciados · D-005 versionar a 00_COLAB_IA no Git · **D-006 entrega mínima FIAP (1 réplica/serviço; HPA só evaluation+analytics min1/max2; node group 2× t3.medium)**.

## 7. Pendências
Ver `PENDENCIAS_E_PROXIMOS_PASSOS.md`. **Próxima tarefa: criar o node group** (2× t3.medium, Min1/Des2/Máx4); o control plane do cluster já está Active.

## 8. Glossário
- **Feature flag:** interruptor que liga/desliga funcionalidade sem novo deploy.
- **EKS:** Kubernetes gerenciado da AWS. **ECR:** registro de imagens Docker.
- **RDS:** banco gerenciado. **ElastiCache:** Redis gerenciado. **SQS:** fila de mensagens. **DynamoDB:** banco NoSQL.
- **Container:** o programa em si. **Pod:** "caixinha" com 1 container (no nosso caso, 1:1). **Nó (node):** a máquina EC2 que roda vários pods. **DaemonSet:** pod de sistema que roda 1 cópia por nó.
- **HPA:** auto-escala de PODS por CPU. **Node group:** grupo de máquinas (auto scaling de NÓS — config Min/Desejado/Máx). **StatefulSet:** workload com estado + disco (PVC). **AZ:** zona de disponibilidade (data center).

## 9. Cuidados
- Nunca commitar segredos. Os secrets têm placeholders; preencher só no deploy (valores na memória privada).
- Região SEMPRE us-east-2 e Account 891376952395 nos comandos.
- Free Tier: máx. 2 instâncias RDS. Por isso o targeting virou pod.
- **Free Tier NÃO roda o cluster:** t3.micro tem limite de ~4 pods/nó (só os DaemonSets já enchem) + 1 GB RAM. O node group usa **t3.medium** (não Free Tier, ~US$0,08/h) — ligar só na demo. Ver D-006.
- AWS Academy tem credencial temporária (~4h) — não usar (D-002).
- (RESOLVIDO 2026-06-29) EKS precisa de 2 AZs — o VPC **já tem** sub-redes em us-east-2a e us-east-2b (4 no total). Ver §4 e F-003.
- Pasta `00_COLAB_IA/` é **versionada no Git** (repo privado) — sincroniza entre máquinas via `git pull`/`push`.

## 10. Resumo das conversas
- **2026-06-25:** testes locais ok (vídeo gravado); infra AWS criada (IAM, ECR, VPC, 2 RDS); bateu o limite de RDS → targeting como pod (aprovado pelo professor); correção de região; manifestos do pod criados; pasta de colaboração montada; DynamoDB, SQS e ElastiCache criados.
- **2026-06-28:** decisão de sincronizar entre 2 notebooks → passamos a versionar a `00_COLAB_IA/` no Git e criamos o `CLAUDE.md` raiz; auditoria e correção das docs.
- **2026-06-29:** validamos a rede (o VPC já tinha 2 AZs → F-003 resolvido); criamos as 2 IAM roles e o **control plane do cluster EKS** (console, Active, K8s 1.30) com Metrics Server como add-on; enxugamos os manifestos para a entrega mínima da FIAP (1 réplica/serviço; HPA evaluation+analytics min1/max2 — D-006). Próximo: node group + add-ons + deploy.

## 11. Memória interna (Claude) ↔ espelho
A memória privada do Claude (`project_togglemaster.md` e afins) NÃO sincroniza entre máquinas nem é lida pelo Codex — esta pasta é a ponte. IDs da AWS e decisões estão duplicados aqui de propósito. **Os valores de segredos (senha do RDS, chave IAM) ficam SÓ na memória privada, não nesta pasta versionada.**

## 12. Instruções iniciais para o próximo assistente (qualquer máquina/agente)
1. `git pull`. Leia o `CLAUDE.md` da raiz → `LEIA-PRIMEIRO` → `PENDENCIAS` → topo do `LOG` → este DOSSIÊ + `DECISOES`.
2. Próxima tarefa concreta: criar o **node group** `workers` (2× t3.medium, Min1/Des2/Máx4) pelo console — o control plane do cluster `togglemaster-cluster` já está Active. Depois: EBS CSI → Nginx → kubectl → secrets → deploy. Detalhes em PENDENCIAS.
3. Trabalhe um passo de cada vez e confirme com o Gabriel antes de avançar. Entregar só o mínimo da FIAP (D-006).
4. Ao terminar: atualize esta pasta (LOG no topo, PENDENCIAS, DECISOES) e dê `git push`.
