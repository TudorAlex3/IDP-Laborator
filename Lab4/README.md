# Lab 4 - Portainer si GitLab CI/CD

## Ce inveti
- **Portainer**: gestiunea vizuala a clusterului Docker Swarm (dashboard, stacks, webhook-uri)
- **GitLab CI/CD**: automatizarea build-ului si deployment-ului cu runners si pipeline-uri
- **Flux complet**: de la `git push` la deploy automat in cluster

## Structura

```
Lab4/
├── docker-compose.portainer.yml    # Stack Portainer (agent + dashboard)
├── docker-compose.app.yml          # Stack aplicatie demo (API + PostgreSQL)
├── api/
│   ├── Dockerfile                  # Imagine Docker pentru API
│   ├── package.json                # Dependinte Node.js
│   └── server.js                   # REST API (GET/POST /api/books)
├── init-scripts/
│   └── init-db.sql                 # Initializare PostgreSQL
├── .gitlab-ci.yml.example          # Exemplu pipeline CI/CD
├── cleanup.sh                      # Script curatenie
└── cheatsheet.md                   # Ghid pas-cu-pas cu explicatii
```

## Porturi expuse

| Serviciu   | Port | Descriere                      |
|------------|------|--------------------------------|
| Portainer  | 9000 | Dashboard HTTP                 |
| Portainer  | 9443 | Dashboard HTTPS                |
| API        | 5000 | REST API (acces direct)        |

## Pornire rapida

```bash
# 1. Initializeaza Swarm
docker swarm init

# 2. Deploy Portainer
docker stack deploy -c docker-compose.portainer.yml portainer

# 3. Acceseaza http://localhost:9000, seteaza admin + parola

# 4. Deploy aplicatia
docker stack deploy -c docker-compose.app.yml lab4

# 5. Testeaza
curl http://localhost:5000/api/books

# 6. Cleanup
bash cleanup.sh
```

## Ghid complet

Vezi [cheatsheet.md](cheatsheet.md) pentru ghidul complet cu explicatii detaliate.
