# Lab 6 - Kubernetes

## Ce inveti
- **Kubernetes (K8s)**: orchestratorul standard din industrie pentru containere
- **kind**: simularea unui cluster Kubernetes local (noduri ca containere Docker)
- **Pod, ReplicaSet, Deployment**: unitatile de baza ale K8s
- **Labels si Selectors**: cum grupam si filtram obiecte
- **ConfigMaps si Secrets**: configurare separata de imagine
- **Services**: expunerea pod-urilor in retea (ClusterIP, NodePort)
- **Bonus proiect**: 0.3p extra daca folositi Kubernetes in loc de Docker Swarm

## Structura

```
Lab6/
├── kind-config.yaml       # Configurare cluster kind (1 control-plane + 2 workers)
├── cleanup.sh             # Script curatenie
└── cheatsheet.md          # Ghid pas-cu-pas cu explicatii
```

## Prerechisite

Trebuie instalate **o singura data** (vezi cheatsheet.md sectiunea 0):
- Docker
- kind (Kubernetes IN Docker)
- kubectl (CLI Kubernetes)

## Pornire rapida

```bash
# 1. Instaleaza kind si kubectl (vezi cheatsheet.md sectiunea 0)

# 2. Creeaza cluster
kind create cluster --config kind-config.yaml

# 3. Verifica
kubectl get nodes

# 4. Cleanup
kind delete cluster
```

## Echivalente Docker Swarm → Kubernetes

| Docker Swarm | Kubernetes | Descriere |
|---|---|---|
| `docker swarm init` | `kind create cluster` | Creare cluster |
| `docker node ls` | `kubectl get nodes` | Listare noduri |
| task | Pod | Cea mai mica unitate |
| service (replicated) | Deployment | Serviciu cu replici |
| service (global) | DaemonSet | Un pod pe fiecare nod |
| `docker service ls` | `kubectl get deploy` | Listare servicii |
| stack | Namespace | Izolare logica |
| configs / secrets | ConfigMap / Secret | Configurare |
| overlay network | Service (ClusterIP) | Retea interna |
| ports | Service (NodePort) | Expunere port |

## Ghid complet

Vezi [cheatsheet.md](cheatsheet.md) pentru ghidul complet cu explicatii detaliate.
