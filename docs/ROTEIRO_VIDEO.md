# 🎬 Roteiro de gravação do vídeo — Tech Challenge Fase 2 (até 20 min)

> **Regra de ouro (feedback do professor na Fase 1):** nunca mostrar uma tela sem narrar.
> Padrão de fala: **"Este é o X, configurado com Y, e escolhemos assim porque Z."**
> Na Fase 1 perdemos pontos por (a) não demonstrar o ambiente local AO VIVO e
> (b) navegar no console AWS sem explicar — este roteiro corrige os dois de propósito.

## ✅ Checklist antes de gravar

1. `docker compose up -d` → esperar tudo `healthy` → `docker compose down` (aquece as imagens).
2. `kubectl get pods -n togglemaster` → 6 pods `Running` (cluster precisa estar LIGADO).
3. Abrir: 2 janelas do PowerShell lado a lado + console AWS em **us-east-2** + este roteiro à parte.
4. ⚠️ O endereço do Load Balancer MUDA se o ingress-nginx for recriado — conferir com
   `kubectl get svc ingress-nginx-controller -n ingress-nginx` e ajustar o comando da Parte 3.

---

## Parte 1 — Ambiente local (~3–4 min)

```powershell
docker compose up -d
docker compose ps
Invoke-RestMethod "http://localhost:8004/evaluate?user_id=u1&flag_name=demo-local"
docker compose down
```

**Narração e porquês:**
- "Cada serviço tem seu **Dockerfile multi-stage**" → **por quê:** imagem final mínima = deploy
  mais rápido e menos superfície de ataque.
- No `ps`, contar: "**9 contêineres** — 5 apps + 2 PostgreSQL + Redis + DynamoDB Local" →
  **por quê DynamoDB Local:** desenvolver sem custo e com paridade dev/prod (12-Factor).
- Na chamada respondendo `result: true`: "o fluxo completo rodando NA MINHA MÁQUINA" —
  esta é a demonstração ao vivo que faltou na Fase 1.
- Transição: "Ambiente local validado. Agora o mesmo sistema em produção na AWS."

## Parte 2 — Infra na nuvem, console narrado (~4–5 min)

Ordem das telas: **EKS (aba Compute) → ECR → RDS → ElastiCache → SQS → DynamoDB**, depois terminal.

- **EKS:** "cluster `togglemaster-cluster` em us-east-2; node group `workers`, auto scaling
  Min 1 / Des 2 / Máx 4" → **por quês:** EKS = control plane gerenciado; 2 máquinas = lugar
  para os pods escalados nascerem; **c7i-flex.large** porque o plano gratuito BLOQUEOU a
  t3.medium ("not eligible for Free Tier") — desafio real do projeto.
- **ECR:** "5 repositórios, um por serviço — o cluster puxa as imagens daqui."
- **RDS (momento-chave):** "2 instâncias (auth, flags). O desafio pedia 3, mas o plano
  gratuito limita a 2 — o banco do targeting roda como POD com disco EBS, solução validada
  com o professor" → **por que não compartilhar uma instância:** cada microsserviço dono do
  seu dado; compartilhar recriaria o acoplamento do monolito.
- **ElastiCache/SQS/DynamoDB:** "gerenciados — não custam quase nada parados e ninguém opera."
- Terminal: `kubectl get nodes` e `kubectl get pods -n togglemaster` → "2 nós Ready, 6 pods
  Running, namespace próprio, requests/limits e probes em todos os deployments."

## Parte 3 — Nginx Ingress (~2 min)

```powershell
curl.exe "http://<LB>/evaluate?user_id=u1&flag_name=demo-fiap" -H "Authorization: Bearer <SERVICE_API_KEY>"
```
(LB e chave atuais no `00_COLAB_IA/PENDENCIAS` e no `evaluation-service/secret.yaml`.)

- "Chamada pública entrando pelo **Load Balancer criado pelo Nginx Ingress**; ele roteia por
  caminho de URL (/evaluate, /flags, /rules)" → **por quê:** um único ponto de entrada e um
  único LB pago, em vez de um por serviço.

## Parte 4 — Escalabilidade do evaluation (~4 min)

Terminal 1 (placar visível o tempo todo):
```powershell
kubectl get hpa -n togglemaster -w
```
Terminal 2 (carga de dentro do cluster):
```powershell
kubectl run load-generator -n togglemaster --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- 'http://evaluation-service:8004/evaluate?user_id=u1&flag_name=demo-fiap' >/dev/null 2>&1; done"
```
Depois que REPLICAS 1→2: `kubectl get pods -n togglemaster` · limpar com
`kubectl delete pod load-generator -n togglemaster`.

- **Por quês para narrar:** gatilho de **70% de CPU** (escala antes de saturar, sem
  desperdício); **Metrics Server** é quem mede; carga gerada de dentro do cluster (não depende
  da internet local); evaluation em **Go + cache Redis de 30s** porque é o hot path.

## Parte 5 — Analytics + SQS + DynamoDB (~4 min)

```powershell
1..200 | ForEach-Object { aws sqs send-message --queue-url https://sqs.us-east-2.amazonaws.com/891376952395/togglemaster-events --region us-east-2 --message-body ('{"event_id":"demo-'+$_+'","flag_name":"demo-fiap","user_id":"u'+$_+'","result":true,"evaluated_at":"2026-07-06T18:00:00Z"}') | Out-Null }
kubectl logs deploy/analytics-service -n togglemaster --tail=10
```
Console: DynamoDB → `ToggleMasterAnalytics` → Explore table items.

- **Por quês:** fila no meio = resposta ao usuário não espera a estatística; analytics fora
  do ar = evento fica na fila (nada se perde); **HPA por CPU e não KEDA** = KEDA era opcional,
  e consumo de fila vira CPU — a solução mais simples que atende o requisito.

## Parte 6 — Fechamento falado (~3 min)

1. **Arquitetura em 30s:** LB → Ingress → 5 serviços no EKS; RDS ×2 + pod do targeting;
   Redis; SQS → analytics → DynamoDB.
2. **Desafios (transparência = elogio na Fase 1):** limite de 2 RDS → banco em pod (aprovado
   pelo professor); t3.medium bloqueada → c7i-flex.large; ajustes finos (porta 5432 no SG,
   StorageClass default, CRLF do Windows).
3. **Escalabilidade do analytics (exigido):** HPA por CPU, justificar simplicidade.
4. **3 data stores (exigido):** RDS = arquivo de aço (durável/relacional) · Redis = post-it
   (cache do hot path) · DynamoDB = esteira do mercado (alto volume sem esquema rígido).

## 🧹 Depois de gravar

Derrubar o que custa: node group `workers` (Desired 0 ou delete) + `kubectl delete ns
ingress-nginx` (remove o LB). Subir o vídeo no YouTube → preencher `docs/RELATORIO_DE_ENTREGA.md`.
