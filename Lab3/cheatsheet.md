# Docker Lab 3 - Cheatsheet

---

# PARTEA I: Docker Compose cu Kong API Gateway

In aplicatiile reale, clientii (browser, mobile) nu vorbesc direct cu fiecare microserviciu. Un **API Gateway** sta in fata tuturor serviciilor si se ocupa de: rutare (cine primeste cererea), autentificare (cine are voie), rate limiting (cate cereri pe secunda), logging si metrici. **Kong** e unul din cele mai populare API Gateway-uri open-source.

---

## 1. Pornire aplicatie completa

Navigheaza in directorul laboratorului.

```bash
docker compose up -d --build
```
> Porneste **6 servicii**: API (Flask), PostgreSQL (baza de date), Adminer (UI pentru DB), Kong (API Gateway), Prometheus (colectare metrici), Grafana (vizualizare metrici). Toate comunica prin reteaua Docker interna.

```bash
docker compose ps
```
> Verifica ca toate 6 serviciile ruleaza. Porturile importante: `5000` (API direct), `8000` (Kong proxy), `9090` (Prometheus), `3000` (Grafana).

```bash
docker compose logs -f
```
> Log-uri de la toate serviciile in timp real. Poti filtra: `docker compose logs -f kong` (doar Kong). `Ctrl+C` pentru a iesi.

---

## 2. Testare API direct (fara Kong)

Intai testam API-ul **fara** gateway, ca sa vedem diferenta.

```bash
curl http://localhost:5000/api/books
```
> Acces **direct** la API pe portul 5000 — ocoleste complet Kong. Oricine poate accesa API-ul fara autentificare. In productie, portul 5000 nu ar fi expus public.

```bash
curl -X POST http://localhost:5000/api/books -H "Content-Type: application/json" -d '{"title":"Kong Gateway Guide","author":"Kong Inc"}'
```
> Adauga o carte direct prin API — fara niciun control de acces.

---

## 3. Testare prin Kong (API Gateway)

Kong este configurat prin fisierul `kong/kong.yml` in modul **DB-less** (declarativ). Rutele si plugin-urile sunt definite in YAML, nu intr-o baza de date.

```bash
curl http://localhost:8000/api/books
```
> Cererea trece prin Kong (portul 8000). **Raspuns: 401 Unauthorized** — ruta `/api/books` are plugin-ul `key-auth` activ. Kong blocheaza cererea inainte sa ajunga la API. Asta e rolul gateway-ului: protectie fara sa modifici codul API-ului.

```bash
curl -H "apikey: mobylab" http://localhost:8000/api/books
```
> Aceeasi cerere, dar cu **cheia API in header**. Kong verifica cheia, o gaseste valida, si redirecteaza cererea catre serviciul API. Raspuns: lista de carti (200 OK).

```bash
curl http://localhost:8000/adminer
```
> Adminer (UI administrare DB) prin Kong — functioneaza **fara cheie API** pentru ca ruta `/adminer` nu are plugin-ul key-auth. Diferite rute pot avea reguli diferite.

---

## 4. Generare trafic (pentru metrici)

Ca sa vedem date in Prometheus si Grafana, trebuie sa generam trafic prin Kong.

```bash
for i in $(seq 20); do curl -s -H "apikey: mobylab" http://localhost:8000/api/books > /dev/null; done
```
> Trimite 20 de cereri valide (cu cheie API). `-s` = silent (fara progress bar). `> /dev/null` = nu afisa raspunsul. Kong inregistreaza fiecare cerere ca metrica (status code, latenta, serviciu).

```bash
for i in $(seq 5); do curl -s http://localhost:8000/api/books > /dev/null; done
```
> Trimite 5 cereri **fara** cheie API. Kong le respinge cu 401 — dar tot le inregistreaza. In Prometheus vei vedea diferenta intre cererile reusie (200) si cele respinse (401).

---

## 5. Prometheus

**Prometheus** este un sistem de monitorizare care **colecteaza metrici** de la servicii la intervale regulate (pull-based). Serviciile expun un endpoint `/metrics` cu date in format text, iar Prometheus le "scrape-uieste" periodic.

Deschide in browser: **http://localhost:9090**

> Interfata web Prometheus. Prometheus colecteaza automat metrici de la Kong la fiecare 15 secunde (configurat in `prometheus/prometheus.yml`).

In campul de query, introdu:

```
kong_http_requests_total
```
> Aceasta este o **metrica de tip counter** — creste doar (numara cererile totale). Prometheus stocheaza si dimensiuni (labels): `code` (status HTTP), `service` (serviciul Kong). Apasa "Execute" pentru a vedea valorile.

```
kong_http_requests_total{code="200"}
```
> Filtreaza cu **label selector**: doar cererile cu raspuns 200 (succes). Sintaxa `{key="value"}` e limbajul de query PromQL.

```
kong_http_requests_total{code="401"}
```
> Cererile respinse (fara cheie API). Compara numarul cu cele de la 200 — reflecta cele 5 cereri fara cheie de la pasul anterior.

```
rate(kong_http_requests_total[1m])
```
> `rate()` calculeaza **rata de crestere** a counter-ului pe secunda, mediata pe ultimul minut (`[1m]`). Rezultatul e "cereri pe secunda". Apasa tab-ul **Graph** pentru vizualizare grafica in timp.

---

## 6. Grafana

**Grafana** este un tool de vizualizare care se conecteaza la surse de date (Prometheus, InfluxDB, etc.) si creeaza **dashboard-uri** cu grafice interactive. Prometheus colecteaza datele, Grafana le face vizibile si usor de interpretat.

Deschide in browser: **http://localhost:3000**

### Pasul 1: Login
> Username: `admin`, Password: `admin`. La prima logare cere schimbarea parolei — apasa "Skip".

### Pasul 2: Adaugare sursa de date Prometheus
> 1. In meniul din stanga: **Connections** -> **Data Sources** -> **Add data source**
> 2. Alege **Prometheus**
> 3. In campul "Prometheus server URL" scrie: `http://prometheus:9090` (numele serviciului din Docker Compose — containerele se gasesc prin nume in reteaua interna)
> 4. Scroll jos -> **Save & Test** -> ar trebui sa apara "Successfully queried the Prometheus API"

### Pasul 3: Import dashboard Kong
> 1. In meniul din stanga: **Dashboards** -> **Create dashboard** -> **Import dashboard**
> 2. In campul de sub "Find and import dashboards..." scrie: `7424` -> apasa **Load** (7424 e ID-ul unui dashboard pre-facut de comunitate pe grafana.com)
> 3. La campul **"DS_PROMETHEUS"** selecteaza **Prometheus** (sursa de date configurata mai sus)
> 4. Apasa **Import**
> 5. Dashboard-ul apare cu grafice: Total Requests, Latency, Requests per Second, Status Codes, etc.
>
> **Nota:** Daca la reimport apare eroare ca dashboard-ul exista deja, apasa **Overwrite**.

### Pasul 4: Demonstratie live

Genereaza trafic si urmareste graficele in timp real:

```bash
for i in $(seq 50); do curl -s -H "apikey: mobylab" http://localhost:8000/api/books > /dev/null; sleep 0.2; done
```
> Trimite 50 de cereri cu pauza de 0.2s intre ele. Pauza face ca traficul sa apara gradual pe grafice, nu ca un singur punct.

> In Grafana, apasa **Refresh** (iconita de reload din dreapta sus) sau seteaza auto-refresh la 5s pentru a vedea datele actualizandu-se live.

---

## 7. Oprire

```bash
docker compose down
```
> Opreste totul, pastreaza volumele. La urmatorul `up`, baza de date va avea aceleasi date, iar Prometheus va avea istoricul de metrici.

```bash
docker compose down -v
```
> Opreste totul si sterge si volumele — start complet de la zero.

---

# PARTEA II: Persistenta - NFS (demonstrativ)

---

## 8. NFS - Teorie si comenzi (demonstrativ)

**NFS (Network File System)** permite partajarea unui director intre masini prin retea. In Docker Swarm, volumele locale sunt o problema: daca un container migheaza pe alt nod, volumul de pe nodul vechi nu e accesibil. NFS rezolva asta — toate nodurile monteaza acelasi director de pe un server central.

**NOTA:** NFS nu functioneaza pe WSL2/Docker Desktop (kernel-ul WSL2 nu are modulul NFS client). Comenzile de mai jos sunt demonstrative si functioneaza pe Linux nativ.

### Comenzile NFS:

```bash
# 1. Pornire server NFS (container)
mkdir -p /cale/director/partajat
docker run -d --name nfs --privileged -v /cale/director/partajat:/nfsshare \
    -e SHARED_DIRECTORY=/nfsshare itsthenetwork/nfs-server-alpine:latest

# 2. Creare volum NFS pe client
docker volume create --driver local --opt type=nfs \
    --opt o=nfsvers=3,addr=IP_SERVER_NFS,rw \
    --opt device=:/nfsshare mynfsvol

# 3. Utilizare volum NFS intr-un container
docker run -v mynfsvol:/data -it alpine

# 4. In Docker Compose / Swarm (fisier YAML)
# volumes:
#     db-data-nfs:
#         driver: local
#         driver_opts:
#             type: nfs
#             o: "nfsvers=3,addr=IP_SERVER,nolock,soft,rw"
#             device: :/database/data
```
> Fluxul: un container ruleaza un server NFS care expune un director -> clientii creeaza un volum Docker de tip NFS care pointeaza la acel director -> containerele monteaza volumul. Rezultat: **aceleasi date accesibile pe orice nod** din cluster.

---

## 9. Cleanup complet

```bash
docker compose down -v
```
> Sterge toate containerele si volumele de laborator.
