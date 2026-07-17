# DOSSIÊ DE CONTEXTO — ToggleMaster Fase 2 (fonte da verdade)

> **TL;DR:** O ToggleMaster tem 5 microsserviços e foi demonstrado com sucesso no AWS EKS
> em 2026-07-06. Vídeo gravado e infraestrutura cara desligada; os RDS de laboratório foram
> excluídos. Em 2026-07-08, o estado atual do repositório foi saneado para futura publicação:
> `.env` local, Secrets com placeholders e bootstrap da chave documentado no README.
>
> **Última atualização:** 2026-07-17 — Claude (Opus 4.8)

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
- Trabalha em **2 notebooks** (trabalho + pessoal); sincroniza código e contexto via Git.
  O repositório pode ser publicado para avaliação, mas segredos ficam fora do Git (D-008).
- Ambiente: conta pessoal AWS, Free Tier, região us-east-2 (Ohio), Account 891376952395.
- Repo: `github.com/fiap-devops-arqcloud-2026/tech-challenge-02`, branch `dev`, preparado
  para futura publicação após a desativação da chave IAM antiga (P-009).

## 4. Arquivos e caminhos
- `CLAUDE.md` (raiz) — lido automaticamente pelo Claude Code; aponta para esta pasta e resume as regras.
- `docker-compose.yaml` — ambiente local (2 postgres, redis, dynamodb-local, 5 apps).
- `services/<svc>/` — código dos 5 microsserviços (+ `db/init.sql` de auth/flag/targeting).
- `infra/k8s/<svc>/` — manifestos K8s por serviço (deployment, service, configmap, secret; HPA em evaluation e analytics; ingress).
- `infra/k8s/postgres-targeting/` — banco targeting como pod (statefulset, service, configmap, secret).
- `infra/k8s/00-namespaces.yaml` — namespace `togglemaster`.
- `GUIA-AWS.md` — guia de deploy (DESATUALIZADO: 3 RDS/us-east-1; ver F-002/P-006 — tem aviso no topo).
- `POSTECH - Tech Challenge - Fase 2.pdf` — enunciado oficial da FIAP (requisitos técnicos + entregáveis).
- `docs/Material aulas/<1..6>/` — PDFs das aulas da FIAP + um `GUIA-ESTUDO-*.html` por módulo (material de estudo para leigos, criado em 2026-07-17).
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
- **RDS `togglemaster-auth` e `togglemaster-flags`:** usados na demonstração e excluídos
  depois da entrega. Nenhuma senha antiga deve ser reutilizada.
- **SQS:** `togglemaster-events` — URL `https://sqs.us-east-2.amazonaws.com/891376952395/togglemaster-events`
- **DynamoDB:** `ToggleMasterAnalytics` (chave `event_id`)
- **ElastiCache:** `togglemaster-redis` — endpoint `togglemaster-redis.ewbn3x.ng.0001.use2.cache.amazonaws.com:6379` (Redis OSS 7.1, sub-rede privada, SG `sg-0e79721741070ef64` com 6379 liberado p/ 10.0.0.0/16). Já no `evaluation-service/configmap.yaml`.
- **Security group da camada de dados:** `sg-0e79721741070ef64` (libera 5432 do RDS e 6379 do Redis para os pods do EKS).
- **EKS `togglemaster-cluster` (criado 2026-06-29, status Active):** pelo console (não eksctl). K8s 1.30, endpoint Public and private, control plane nas 2 sub-redes públicas, sem scaling tier, sem Auto Mode. Add-ons: CoreDNS, kube-proxy, Amazon VPC CNI, EKS Pod Identity Agent, Node monitoring agent, **Metrics Server** (community). Observability/logs desligados.
- **Histórico do deploy:** node group `workers` (2× c7i-flex.large — D-007), EBS CSI Driver e Nginx Ingress foram criados em 2026-07-06 e a aplicação rodou ponta a ponta. **Toda essa infra foi EXCLUÍDA em 2026-07-09** (custo ~US$0). Para religar: seguir o `GUIA-AWS.md` do zero e gerar credenciais novas.

## 5. Processos
- Build/push: `docker compose build` → tag → push para ECR (us-east-2) e DockerHub (`tocaccelli/*`).
- Deploy: criar EKS → node group → add-ons → conectar kubectl → preencher secrets/configmaps → `kubectl apply -f infra/k8s/...`.
- Custo: subir o EKS (control plane ~US$0,10/h) + node group (2× t3.medium ~US$0,08/h) só na hora da demo e derrubar depois. DynamoDB/SQS ~custo zero parados; ElastiCache + 2 RDS ficam ligados (derrubar após a entrega).
- Sincronizar entre notebooks: `git pull` ao começar, `git push` ao terminar.

## 6. Decisões
Ver `DECISOES.md`. Resumo: D-001 targeting como pod · D-002 não Academy · D-003 us-east-2 · D-004 ElastiCache/SQS/DynamoDB gerenciados · D-005 versionar a 00_COLAB_IA no Git · **D-006 entrega mínima FIAP (1 réplica/serviço; HPA só evaluation+analytics min1/max2; node group 2× t3.medium)**.

## 7. Pendências
Ver `PENDENCIAS_E_PROXIMOS_PASSOS.md`. **Fase 2 ENTREGUE** (deploy 2026-07-06, vídeo publicado, infra excluída 2026-07-09). Nada pendente de entrega; única pendência aberta é **P-009** (excluir em definitivo a chave IAM antiga antes de eventual publicação do repo).

## 8. Glossário
- **Feature flag:** interruptor que liga/desliga funcionalidade sem novo deploy.
- **EKS:** Kubernetes gerenciado da AWS. **ECR:** registro de imagens Docker.
- **RDS:** banco gerenciado. **ElastiCache:** Redis gerenciado. **SQS:** fila de mensagens. **DynamoDB:** banco NoSQL.
- **Container:** o programa em si. **Pod:** "caixinha" com 1 container (no nosso caso, 1:1). **Nó (node):** a máquina EC2 que roda vários pods. **DaemonSet:** pod de sistema que roda 1 cópia por nó.
- **HPA:** auto-escala de PODS por CPU. **Node group:** grupo de máquinas (auto scaling de NÓS — config Min/Desejado/Máx). **StatefulSet:** workload com estado + disco (PVC). **AZ:** zona de disponibilidade (data center).

## 9. Cuidados
- Nunca commitar segredos. O `.env` é ignorado e os manifestos `secret.yaml` versionados
  têm somente placeholders. Preencher apenas na cópia local.
- Região SEMPRE us-east-2 e Account 891376952395 nos comandos.
- Free Tier: máx. 2 instâncias RDS. Por isso o targeting virou pod.
- **Free Tier NÃO roda o cluster:** t3.micro tem limite de ~4 pods/nó (só os DaemonSets já enchem) + 1 GB RAM. O node group usa **t3.medium** (não Free Tier, ~US$0,08/h) — ligar só na demo. Ver D-006.
- AWS Academy tem credencial temporária (~4h) — não usar (D-002).
- (RESOLVIDO 2026-06-29) EKS precisa de 2 AZs — o VPC **já tem** sub-redes em us-east-2a e us-east-2b (4 no total). Ver §4 e F-003.
- Pasta `00_COLAB_IA/` é versionada e pode ficar pública; não registrar credenciais nela.

## 10. Resumo das conversas
- **2026-06-25:** testes locais ok (vídeo gravado); infra AWS criada (IAM, ECR, VPC, 2 RDS); bateu o limite de RDS → targeting como pod (aprovado pelo professor); correção de região; manifestos do pod criados; pasta de colaboração montada; DynamoDB, SQS e ElastiCache criados.
- **2026-06-28:** decisão de sincronizar entre 2 notebooks → passamos a versionar a `00_COLAB_IA/` no Git e criamos o `CLAUDE.md` raiz; auditoria e correção das docs.
- **2026-06-29:** validamos a rede (o VPC já tinha 2 AZs → F-003 resolvido); criamos as 2 IAM roles e o **control plane do cluster EKS** (console, Active, K8s 1.30) com Metrics Server como add-on; enxugamos os manifestos para a entrega mínima da FIAP (1 réplica/serviço; HPA evaluation+analytics min1/max2 — D-006). Próximo: node group + add-ons + deploy.
- **2026-07-06:** **DEPLOY COMPLETO** — node group (2× c7i-flex.large — D-007), EBS CSI Driver e Nginx Ingress criados; app verificada ponta a ponta (flags via LB, evento SQS→analytics→DynamoDB, HPAs). **Vídeo gravado** e cluster derrubado logo após.
- **2026-07-08:** repo saneado para eventual publicação (`.env` local, secrets com placeholders — D-008); chave IAM antiga desativada; docs de replicação (README/GUIA-AWS) alinhadas. Vídeo publicado (`https://youtu.be/YpunNwLpf40`).
- **2026-07-09:** infra AWS cara **TOTALMENTE excluída** (EKS, 2 RDS, ElastiCache, EBS órfão) — custo ~US$0. Sobra só DynamoDB/SQS/ECR no Free Tier.
- **2026-07-17:** sessão didática — criados **6 guias de estudo para leigos** (um por módulo, em `docs/Material aulas/`) + tabela "Recursos avançados do Kubernetes" no README. Sem mudança de infra ou de arquitetura.

## 11. Memória interna (Claude) ↔ espelho
A pasta `00_COLAB_IA/` é a ponte entre agentes. IDs não secretos e decisões podem ser
registrados, mas senhas, tokens e chaves não devem ser copiados para documentação ou memória.

## 12. Instruções iniciais para o próximo assistente (qualquer máquina/agente)
1. Leia `LEIA-PRIMEIRO` → `PENDENCIAS` → topo do `LOG` → este DOSSIÊ + `DECISOES`.
2. Antes de tornar público: concluir P-009, especialmente desativar a chave IAM antiga.
3. Para testar localmente, seguir o README e criar uma `SERVICE_API_KEY` no banco novo.
4. Nunca reutilizar valores recuperáveis no histórico Git (D-008).
5. Ao terminar: atualizar LOG, PENDENCIAS e DECISOES; publicar somente quando solicitado.
