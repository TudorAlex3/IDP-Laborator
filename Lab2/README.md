# Lab 2 - Docker Compose si Docker Swarm

## Ce inveti
- **Docker Compose**: definirea aplicatiilor multi-serviciu in YAML, gestionarea serviciilor impreuna
- **Docker Swarm**: clustering, managementul nodurilor, stive, replicare, scalare
- **Secrets**: gestionarea securizata a credentialelor in Swarm

## Structura

```
Lab2/
├── api/
│   ├── Dockerfile              # Imaginea API-ului (Node.js + Express + pg)
│   ├── package.json            # Dependinte Node.js
│   └── server.js               # REST API (GET/POST /api/books)
├── init-scripts/
│   └── init-db.sql             # Script initializare PostgreSQL (tabel books)
├── docker-compose.yml          # Configuratie Compose (dezvoltare locala)
├── docker-compose.swarm.yml    # Configuratie Swarm (cu replici si deploy)
├── db-secret.txt               # Fisier secret (parola DB)
├── setup-swarm-dind.sh         # Script setup cluster Swarm cu dind
├── cleanup.sh                  # Script curatenie
└── cheatsheet.md               # Ghid pas-cu-pas cu explicatii
```

## Pornire rapida

### Docker Compose (local)
```bash
docker compose up -d --build
curl http://localhost:5000/api/books
docker compose down -v
```

### Docker Swarm (cluster cu dind)
```bash
# 1. Build imagine API
docker build -t idp-lab2-api:latest ./api

# 2. Setup cluster
bash setup-swarm-dind.sh

# 3. Deploy stiva
docker stack deploy -c docker-compose.swarm.yml lab2

# 4. Testare
curl http://localhost:8080

# 5. Cleanup
bash cleanup.sh
```

## Ghid complet

Vezi [cheatsheet.md](cheatsheet.md) pentru ghidul complet cu explicatii detaliate.
