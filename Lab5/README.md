# Lab 5 - Monitorizare, Logging, Vizualizare, Cozi de mesaje

## Ce inveti
- **Prometheus**: colectare metrici de la servicii, noduri si containere
- **Node Exporter + cAdvisor**: metrici hardware si per container
- **Loki**: agregare centralizata de log-uri ("Prometheus pentru log-uri")
- **Grafana**: dashboards vizuale pentru metrici si log-uri
- **RabbitMQ**: comunicare asincrona intre microservicii (publish/subscribe)

## Structura

```
Lab5/
├── Docker/
│   ├── prometheus-stack.yml                                    # Doar Prometheus
│   ├── prometheus-nexporter-stack.yml                          # + Node Exporter
│   ├── prometheus-nexporter-cadvisor-stack.yml                 # + cAdvisor
│   ├── prometheus-nexporter-cadvisor-testapp-stack.yml         # + Testapp (metrici custom)
│   ├── prometheus-nexporter-cadvisor-testapp-loki-stack.yml    # + Loki + Grafana
│   └── prometheus-nexporter-cadvisor-testapp-loki-rmq-stack.yml  # + RabbitMQ + Worker
├── Configs/
│   ├── prometheus.yml                          # Config Prometheus (doar self-monitoring)
│   ├── prometheus-nexporter.yml                # + target Node Exporter
│   ├── prometheus-nexporter-cadvisor.yml       # + target cAdvisor
│   ├── prometheus-nexporter-cadvisor-testapp.yml  # + target Testapp
│   └── loki/
│       └── loki.yml                            # Config Loki
├── cleanup.sh                                  # Script curatenie
└── cheatsheet.md                               # Ghid pas-cu-pas cu explicatii
```

## Porturi expuse

| Serviciu        | Port  | Descriere                          |
|-----------------|-------|------------------------------------|
| Prometheus      | 9090  | Dashboard metrici + PromQL         |
| Node Exporter   | 9100  | Metrici hardware (intern)          |
| cAdvisor        | 8080  | Metrici per container              |
| Testapp metrics | 8000  | Endpoint /metrics (Prometheus)     |
| Testapp API     | 5000  | Endpoint-uri POST (metrici + MQ)  |
| Grafana         | 3000  | Dashboards (admin/admin)           |
| Loki            | 3100  | Agregare log-uri (intern)          |
| RabbitMQ UI     | 15672 | Management UI (guest/guest)        |

## Pornire rapida

```bash
# 1. Initializeaza Swarm
docker swarm init

# 2. Deploy complet (cu tot: Prometheus, Loki, Grafana, RabbitMQ)
docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
docker stack deploy -c Docker/prometheus-nexporter-cadvisor-testapp-loki-rmq-stack.yml prom

# 3. Acceseaza serviciile
# Prometheus: http://localhost:9090
# Grafana:    http://localhost:3000 (admin/admin)
# RabbitMQ:   http://localhost:15672 (guest/guest)
# cAdvisor:   http://localhost:8080

# 4. Cleanup
bash cleanup.sh
```

## Ghid complet

Vezi [cheatsheet.md](cheatsheet.md) pentru ghidul complet cu explicatii detaliate.
