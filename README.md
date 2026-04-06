# Laboratoare IDP - Instrumente pentru Dezvoltarea Programelor

Acest repository contine laboratoarele practice pentru cursul IDP (Instrumente pentru Dezvoltarea Programelor).

## Laboratoare

| Lab | Tema | Concepte cheie |
|-----|------|---------------|
| [Lab1](Lab1/) | Bazele Docker | Imagini, containere, Dockerfile, networking, volume |
| [Lab2](Lab2/) | Docker Compose & Swarm | Aplicatii multi-serviciu, clustering, scalare, secrets |
| [Lab3](Lab3/) | API Gateway & Monitorizare | Kong, Prometheus, Grafana, persistenta NFS |
| [Lab4](Lab4/) | Portainer & GitLab CI/CD | Gestiune vizuala cluster, webhook-uri, pipeline-uri, runners |
| [Lab5](Lab5/) | Monitorizare, Logging, Cozi de mesaje | Prometheus, Node Exporter, cAdvisor, Loki, Grafana, RabbitMQ |
| [Lab6](Lab6/) | Kubernetes | kind, Pod, ReplicaSet, Deployment, Service, ConfigMap, Secret |

## Structura

Fiecare director de laborator contine:
- **`cheatsheet.md`** — ghid pas-cu-pas cu comenzi si explicatii
- Codul sursa si fisierele de configurare necesare
- Scripturi de cleanup unde e cazul

## Cerinte

- [Docker](https://docs.docker.com/get-docker/) instalat si functional
- [Docker Compose](https://docs.docker.com/compose/install/) (inclus in Docker Desktop)
- Cunostinte de baza de terminal/CLI
- `curl` pentru testarea API-urilor
- [kind](https://kind.sigs.k8s.io/) si [kubectl](https://kubernetes.io/docs/tasks/tools/) pentru Lab6 (Kubernetes)
