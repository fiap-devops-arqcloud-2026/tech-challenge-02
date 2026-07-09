# FIAP — Tech Challenge – Fase 2 – Grupo 203

> **Fonte do PDF de entrega** (`FIAP - Tech Challenge - Fase 2 - Grupo 203.pdf`, nesta pasta).
> Exigências do PDF da Fase 2 (pág. 9): participantes (nome, RM, Discord), link do repositório e link do vídeo.

## Participantes

| Nome | RM | Discord |
|---|---|---|
| Douglas Deveza dos Santos | RM373827 | d0guera |
| Gabriel Pinelli Silva | RM373763 | tocaccelly |
| João Carlos da Silva Brito | RM371738 | durmiand |
| João Gabriel da Cruz Sales | RM372444 | jgabrieldev |
| João Vitor de Jesus Ciardullo | RM372155 | joaozinho1403 |

## Links

- **Repositório:** https://github.com/fiap-devops-arqcloud-2026/tech-challenge-02
- **Vídeo da demonstração:** https://youtu.be/YpunNwLpf40
- **Pontuação extra (opcional):** o grupo ainda não concluiu a trilha do Google Cloud Skills Boost — se alguém concluir antes do prazo, incluir aqui o link do badge público (+10 pts)

## Resumo dos desafios encontrados e decisões tomadas

*(Seção extra, no espírito da Fase 1 — o detalhamento completo, com diagrama, está em
[`docs/ARQUITETURA.md`](./ARQUITETURA.md) no repositório.)*

Nesta fase, o ToggleMaster deixou de ser um monolito e virou um ecossistema de **5 microsserviços**
(Go e Python) implantado em **Kubernetes na AWS (EKS)**, com Nginx Ingress, HPA por CPU no
evaluation-service e no analytics-service, e o caminho assíncrono evaluation → SQS → analytics →
DynamoDB funcionando de ponta a ponta.

**Principais desafios e como foram resolvidos:**

1. **Limite de 2 instâncias RDS no plano gratuito da AWS** — o terceiro banco (targeting) foi
   implantado como um pod PostgreSQL dentro do cluster, com disco EBS persistente (StatefulSet).
   Solução validada com o professor.
2. **O plano gratuito bloqueou a instância t3.medium** planejada para os nós — substituída pela
   c7i-flex.large (2 vCPU / 4 GB, equivalente e permitida pelo plano).
3. **Escalabilidade do analytics por HPA de CPU** (e não KEDA, que era opcional): quando a fila SQS
   enche, o worker processa mais mensagens, a CPU sobe e o HPA escala os pods — atende o requisito
   com a solução mais simples.
4. **Três data stores com papéis distintos:** RDS para dados relacionais duráveis (chaves e flags),
   ElastiCache/Redis como cache do hot path e DynamoDB para o alto volume de eventos de analytics.
