# Lab 3 - API Gateway si Monitorizare

## Ce inveti
- **Kong API Gateway**: rutare, autentificare (key-auth), mod DB-less
- **Prometheus**: colectare metrici, query-uri PromQL
- **Grafana**: dashboard-uri, surse de date, vizualizare
- **NFS**: sistem de fisiere partajat in retea (teorie)

## Structura

```
Lab3/
├── api/
│   ├── Dockerfile          # Imaginea API (Node.js, port 80)
│   ├── package.json        # Dependinte: express, pg
│   └── server.js           # REST API: GET/POST /api/books, GET /api/health
├── init-scripts/
│   └── init-db.sql         # Initializare PostgreSQL (CREATE TABLE books + date)
├── kong/
│   ├── kong.yml            # Configurare Kong DB-less: key-auth pe books-service
│   └── kong-plugins.yml    # Configurare extinsa: rate-limiting, cors, bot-detection, prometheus
├── prometheus/
│   └── prometheus.yml      # Configurare scrape: metrici Kong pe :8001
├── docker-compose.yml      # Stiva completa: api, postgres, adminer, kong, prometheus, grafana
├── setup-nfs.sh            # Script setup NFS server + volum
├── cleanup.sh              # Script curatenie
└── cheatsheet.md           # Ghid pas-cu-pas cu explicatii
```

## Porturi expuse

| Serviciu   | Port | Descriere                      |
|------------|------|--------------------------------|
| API        | 5000 | REST API (acces direct)        |
| Kong Proxy | 8000 | HTTP proxy                     |
| Kong SSL   | 8443 | HTTPS proxy                    |
| Prometheus | 9090 | Interfata metrici              |
| Grafana    | 3000 | Dashboard-uri (admin/admin)    |

## Pornire rapida

```bash
docker compose up -d --build

# Acces direct la API
curl http://localhost:5000/api/books

# Prin Kong (necesita cheie API)
curl -H "apikey: mobylab" http://localhost:8000/api/books

# Cleanup
docker compose down -v
```

## Ghid complet

Vezi [cheatsheet.md](cheatsheet.md) pentru ghidul complet cu explicatii detaliate.
