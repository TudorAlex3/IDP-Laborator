# Docker Lab 5 - Cheatsheet

---

# PARTEA I: Monitorizare

Docker ofera cateva comenzi de baza pentru monitorizare din terminal, dar pentru monitorizare pe termen lung avem nevoie de unelte specializate. In acest laborator vom folosi **Prometheus** (colectare metrici), **Node Exporter** (metrici hardware), **cAdvisor** (metrici per container) si **Grafana** (vizualizare dashboards).

---

## 1. Pornire Docker si initializare Swarm

```bash
sudo service docker start
```
> Porneste Docker daemon-ul. Pe WSL2, Docker nu porneste automat — trebuie pornit manual dupa fiecare restart al sistemului.

```bash
docker swarm init
```
> Initializeaza cluster-ul Swarm. Toate serviciile din acest laborator vor rula ca servicii Swarm.

---

## 2. Monitorizare din terminal

Inainte de Prometheus, Docker ofera monitorizare de baza:

```bash
docker run --name busy -d alpine sh -c "while true; do :; done"
docker run --name idle -d alpine sleep 3600
```
> Pornim doua containere — unul cu load (loop infinit), unul idle.

```bash
docker stats --no-stream
```
> Afiseaza un snapshot cu CPU, memorie, I/O pentru fiecare container. `busy` va consuma CPU, `idle` va fi la ~0%. E ca un Task Manager pentru containere.

```bash
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" --no-stream
```
> Acelasi lucru cu format custom — doar coloanele care ne intereseaza.

```bash
docker stop busy idle && docker rm busy idle
```
> Curatam containerele de test.

**Limitari:** `docker stats` nu salveaza nimic — vedeti doar ce se intampla ACUM. Nu aveti istoric si nu aveti alerte. Pentru asta folosim Prometheus.

---

## 3. Prometheus — colectare metrici cu istoric

**Prometheus** este un toolkit open-source de monitorizare. Functioneaza pe un model **PULL**: serviciile expun un endpoint `/metrics` (un URL HTTP care returneaza metrici in format text), iar Prometheus vine periodic si le citeste. Metricile sunt stocate ca **serii de timp** — valori cu timestamp — deci puteti vedea cum evolueaza o metrica in timp.

### Deploy Prometheus

```bash
docker stack deploy -c Docker/prometheus-stack.yml prom
```
> Deployeaza Prometheus ca serviciu Swarm. Fisierul `Configs/prometheus.yml` ii spune ce sa monitorizeze.

```bash
docker stack services prom
```
> Verificati ca serviciul e activ (1/1 REPLICAS).

### Interfata web

- **http://localhost:9090/targets** — vedeti toate target-urile monitorizate si statusul lor (UP = verde, DOWN = rosu)
- **http://localhost:9090/graph** — faceti query-uri PromQL. Incercati: `up` (arata care target-uri sunt active)
- **http://localhost:9090/metrics** — metricile propriului Prometheus

---

## 4. Node Exporter — metrici de hardware

Prometheus monitorizeaza aplicatii, dar nu stie cat CPU are masina, cata memorie libera sau cat disk. **Node Exporter** ruleaza pe fiecare nod si expune metrici de sistem (CPU, memorie, disk, retea).

```bash
docker stack deploy -c Docker/prometheus-nexporter-stack.yml prom
```
> Adauga Node Exporter ca serviciu global (o instanta pe fiecare nod). Nu trebuie sa faceti `docker stack rm` inainte — Swarm face update in-place.

### Verificare

- **http://localhost:9090/targets** — apare si target-ul `node_resources` cu status UP
- **http://localhost:9090/graph** — incercati:
  - `node_memory_MemAvailable_bytes` (RAM liber)
  - `node_cpu_seconds_total` (utilizare CPU)
  - Apasati tab-ul **Graph** ca sa vedeti evolutia in timp

---

## 5. cAdvisor — metrici per container

Node Exporter monitorizeaza nodul (hardware-ul). **cAdvisor** (Container Advisor, facut de Google) monitorizeaza fiecare **container** in parte — cat CPU si memorie consuma.

cAdvisor face sampling o data pe secunda, dar tine datele doar un minut. De aceea il integram cu Prometheus care le stocheaza pe termen lung.

```bash
docker stack deploy -c Docker/prometheus-nexporter-cadvisor-stack.yml prom
```

### Verificare

- **http://localhost:8080/** — interfata web proprie cAdvisor. Click pe Docker Containers pentru metrici per container
- **http://localhost:9090/targets** — apare si `cadvisor` UP
- **http://localhost:9090/graph** — incercati:
  - `container_memory_usage_bytes` (memorie per container)
  - `container_cpu_usage_seconds_total` (CPU per container)

---

## 6. Monitorizarea propriilor aplicatii

Pana acum am monitorizat Docker, hardware-ul si containerele. Dar cum monitorizam **codul nostru**? Trebuie sa expunem un endpoint `/metrics` din aplicatie. Exista biblioteci client pentru orice limbaj (Python, Go, Java, Node.js).

### Tipuri de metrici Prometheus

| Tip | Descriere | Exemplu |
|-----|-----------|---------|
| **Counter** | Contor care doar creste (sau se reseteaza la 0) | Numar total de request-uri |
| **Gauge** | Valoare care urca si coboara | Numar de useri activi |
| **Histogram** | Distributie de valori in bucket-uri | Durata request-urilor |
| **Summary** | Similar Histogram, cu percentile | p99 latency |

### Deploy testapp (aplicatie Python cu metrici custom)

```bash
docker stack deploy -c Docker/prometheus-nexporter-cadvisor-testapp-stack.yml prom
```

### Verificare metrici

```bash
curl http://localhost:8000/metrics
```
> Returneaza metrici Prometheus in format text: `my_counter_total`, `my_gauge`, `my_summary`, `my_histogram`.

### Modificare metrici (endpoint-uri POST)

```bash
curl -X POST http://localhost:5000/inc_counter
curl -X POST http://localhost:5000/inc_gauge
curl -X POST http://localhost:5000/dec_gauge
curl -X POST http://localhost:5000/set_gauge -d "value=42"
```
> Incrementeaza/decrementeaza metricile custom. Verificati ca s-au schimbat cu `curl http://localhost:8000/metrics`.

### In Prometheus

- **http://localhost:9090/targets** — testapp e UP
- **http://localhost:9090/graph** — query `my_counter_total` sau `my_gauge`

---

# PARTEA II: Logging cu Loki

Monitorizarea ne da **metrici** (numere). Dar cand ceva nu merge, avem nevoie de **log-uri** (text): ce eroare, ce request, ce stack trace. **Loki** colecteaza log-urile din toate containerele Docker si le centralizeaza intr-un singur loc. E descris ca "Prometheus pentru log-uri".

---

## 7. Instalare plugin Loki

```bash
docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
```
> Instaleaza un plugin Docker care redirecteaza log-urile containerelor catre Loki. Pe un cluster real, trebuie instalat pe **fiecare nod**!

```bash
docker plugin ls
```
> Verificati ca `loki` apare cu ENABLED = true.

---

## 8. Deploy Loki + Grafana

```bash
docker stack deploy -c Docker/prometheus-nexporter-cadvisor-testapp-loki-stack.yml prom
```
> Adauga Loki (port 3100, colecteaza log-uri) si Grafana (port 3000, vizualizare). Testapp-ul acum trimite log-urile catre Loki prin logging driver. Loki si Grafana pot dura 20-30s pana pornesc.

> **Nota WSL2:** Versiunile recente de Loki au comunicare interna pe gRPC (port 9095) care nu functioneaza prin overlay network-ul Docker Swarm pe WSL2. Config-ul din `Configs/loki/loki.yml` contine deja fix-ul necesar (`instance_addr: 127.0.0.1`, `frontend_worker.frontend_address: 127.0.0.1:9095`, `query_scheduler.use_scheduler_ring: false`). Daca primiti eroarea "An error occurred within the plugin" in Grafana la Loki, verificati ca folositi config-ul actualizat si faceti un redeploy curat (`docker stack rm prom`, asteptati 15s, apoi deploy din nou).

---

# PARTEA III: Vizualizare cu Grafana

**Grafana** este o platforma de vizualizare cu dashboards. Conectam atat Loki (log-uri) cat si Prometheus (metrici) — un singur loc pentru tot.

---

## 9. Configurare Grafana

Deschideti **http://localhost:3000/** si logati-va cu **admin / admin**.

### Adaugare Loki ca data source (log-uri)

1. Meniu stanga → **Connections** → **Data Sources** → **Add data source**
2. Selectati **Loki**
3. URL: `http://loki:3100`
4. **Save & Test**

### Vizualizare log-uri

Generati log-uri (orice request la testapp produce log-uri):

```bash
curl -X POST http://localhost:5000/inc_counter
curl -X POST http://localhost:5000/inc_gauge
curl -X POST http://localhost:5000/set_gauge -d "value=100"
```

1. Meniu stanga → **Explore**
2. Selectati **Loki** ca data source
3. Label filters: `container_name` → selectati containerul testapp
4. **Run query** → vedeti log-urile cu timestamp

### Adaugare Prometheus ca data source (metrici)

1. **Connections** → **Data Sources** → **Add data source**
2. Selectati **Prometheus**
3. URL: `http://prometheus:9090`
4. **Save & Test**

### Creare dashboard

1. Meniu stanga → **Dashboards** → **New** → **New Dashboard** → **Add visualization**
2. Selectati **Prometheus** ca data source
3. Metric: `my_counter_total` → **Run queries**
4. **Apply** → **Save dashboard**

> Puteti importa dashboards predefinite: **Dashboards** → **Import** → ID `1860` (Node Exporter Full).

---

# PARTEA IV: Cozi de mesaje cu RabbitMQ

Pana acum comunicarea intre microservicii a fost **sincrona** — un serviciu trimite request HTTP si asteapta raspunsul. Daca procesarea dureaza mult (ex: trimitere email), utilizatorul asteapta degeaba.

**Solutia:** Comunicare **asincrona** cu cozi de mesaje. Serviciul pune mesajul in coada si continua — nu asteapta. Un worker separat preia mesajul si il proceseaza in background.

**RabbitMQ** este cel mai popular broker de mesaje open-source. Functioneaza pe modelul **publish/subscribe**:
- **Publisher** pune mesaje in coada
- **RabbitMQ** (broker) stocheaza mesajele in cozi
- **Subscriber** (worker) se aboneaza la coada si primeste mesajele

Pentru Python se foloseste pachetul **Pika** (implementeaza protocolul AMQP folosit de RabbitMQ).

---

## 10. Deploy RabbitMQ + Worker

```bash
docker stack deploy -c Docker/prometheus-nexporter-cadvisor-testapp-loki-rmq-stack.yml prom
```
> Adauga RabbitMQ (broker, port 15672 management UI) si un worker (consumer care asculta pe coada `task_queue`). Testapp-ul devine publisher.

### Acces RabbitMQ Management UI

Deschideti **http://localhost:15672/** si logati-va cu **guest / guest**.

---

## 11. Testare flux publish/subscribe

Trimitem un mesaj din testapp (publisher) → RabbitMQ (coada) → worker (consumer):

```bash
curl -X POST http://localhost:5000/generate_event -d "event=hello_rabbitmq"
```
> Testapp-ul pune mesajul in coada `task_queue`. Returneaza "OK".

Verificam ca worker-ul l-a preluat:

```bash
docker service logs prom_worker --tail 5
```
> Ar trebui sa vedeti `Received hello_rabbitmq`.

Trimiteti mai multe mesaje:

```bash
curl -X POST http://localhost:5000/generate_event -d "event=primul"
curl -X POST http://localhost:5000/generate_event -d "event=al_doilea"
curl -X POST http://localhost:5000/generate_event -d "event=al_treilea"
```

```bash
docker service logs prom_worker --tail 10
```
> Toate mesajele au fost primite de worker. Procesarea s-a facut asincron — testapp-ul nu a asteptat dupa worker.

In RabbitMQ UI (**http://localhost:15672/** → tab **Queues**) vedeti `task_queue` cu statistici: cate mesaje au trecut, cate sunt in asteptare.

### Demo: mesaje persistente in coada

Daca mesajele dispar prea repede (worker-ul le consuma instant), opriti worker-ul ca sa vedeti mesajele acumulate in coada:

```bash
docker service scale prom_worker=0
```
> Worker-ul e oprit — nimeni nu mai consuma din coada.

```bash
curl -X POST http://localhost:5000/generate_event -d "event=mesaj_1"
curl -X POST http://localhost:5000/generate_event -d "event=mesaj_2"
curl -X POST http://localhost:5000/generate_event -d "event=mesaj_3"
```
> Trimiteti mesaje. In RabbitMQ UI (**Queues** → `task_queue`) vedeti **3 mesaje Ready** acumulate.

```bash
docker service scale prom_worker=1
```
> Porniti worker-ul inapoi. Mesajele sunt consumate instant, coada revine la 0. Verificati cu `docker service logs prom_worker --tail 10`.

> **Concluzie:** mesajele sunt **persistente** (durable) — daca worker-ul e oprit, mesajele asteapta in coada. Cand worker-ul revine, le preia pe toate. Nimeni nu pierde nimic.

---

## 12. Cleanup

```bash
docker stack rm prom
```
> Sterge toata stiva de servicii.

```bash
sleep 10
```

```bash
docker plugin rm loki --force 2>/dev/null
```
> Sterge plugin-ul Loki.

```bash
docker swarm leave --force
```
> Paraseste cluster-ul Swarm.
