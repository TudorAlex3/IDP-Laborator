# Docker Lab 2 - Cheatsheet

---

# PARTEA I: Docker Compose

Docker Compose rezolva o problema practica: aplicatiile reale au **mai multe servicii** (API, baza de date, cache, etc.). In loc sa rulezi manual `docker run` pentru fiecare, le definesti pe toate intr-un fisier `docker-compose.yml` si le pornesti cu o singura comanda.

---

## 1. Pornire aplicatie cu Docker Compose

Navigheaza in directorul laboratorului.

```bash
docker compose up -d --build
```
> `up` = porneste tot ce e definit in `docker-compose.yml`. `--build` = reconstruieste imaginile (util dupa modificari in cod). `-d` = background. Compose creeaza automat o **retea** comuna intre servicii — de aceea API-ul poate vorbi cu PostgreSQL folosind doar numele serviciului.

```bash
docker compose ps
```
> Echivalentul `docker ps`, dar filtrat doar pentru serviciile din Compose. Arata porturile expuse si starea fiecarui serviciu.

```bash
docker compose logs -f
```
> Afiseaza log-urile **tuturor** serviciilor intercalate, in timp real. `-f` = follow (ca `tail -f`). `Ctrl+C` pentru a iesi. Poti filtra: `docker compose logs -f api` (doar serviciul `api`).

---

## 2. Testare aplicatie

Acum ai o aplicatie REST care ruleaza: un API Flask conectat la o baza de date PostgreSQL. Testam cu `curl` (client HTTP din terminal).

```bash
curl http://localhost:5000/api/books
```
> **GET** request — citeste resursa. Returneaza lista de carti din baza de date in format JSON. Portul 5000 e cel expus de serviciul API in `docker-compose.yml`.

```bash
curl -X POST http://localhost:5000/api/books -H "Content-Type: application/json" -d '{"title":"Docker Deep Dive","author":"Nigel Poulton"}'
```
> **POST** request — creeaza o resursa noua. `-X POST` specifica metoda HTTP. `-H` seteaza un header (tipul continutului). `-d` trimite datele in body (payload JSON). Raspunsul confirma cartea adaugata cu un ID generat automat de baza de date.

```bash
curl http://localhost:5000/api/books
```
> GET din nou — acum apare si cartea adaugata. Datele persista in PostgreSQL (intr-un volum Docker definit in `docker-compose.yml`).

---

## 3. Oprire Docker Compose

```bash
docker compose down
```
> Opreste si sterge containerele si retelele create de Compose. **Volumele raman** — la urmatorul `docker compose up`, baza de date va avea aceleasi date.

```bash
docker compose down -v
```
> Opreste totul si sterge **inclusiv volumele**. Datele din PostgreSQL se pierd. Foloseste asta cand vrei un start complet de la zero.

---

# PARTEA II: Docker Swarm

Docker Swarm transforma mai multe masini intr-un **cluster**: un grup de masini care se comporta ca una singura. In loc sa faci deploy manual pe fiecare masina, dai o comanda si Swarm distribuie automat containerele pe nodurile disponibile.

Roluri in cluster: **Manager** = coordoneaza (decide unde ruleaza ce), **Worker** = executa (ruleaza containerele).

---

## 4. Creare cluster Swarm pe masina locala

In productie, ai masini fizice/VM-uri separate. La laborator, simulam workerii cu **Docker-in-Docker (dind)**: containere care au Docker instalat inauntru si se comporta ca masini separate.

### Pasul 1: Initializare Swarm

```bash
docker swarm init
```
> Masina curenta devine **manager** (si leader). Comanda afiseaza un token — o cheie de acces pe care workerii o folosesc ca sa se alature cluster-ului. Tokenul contine informatii criptate despre cluster.

```bash
docker node ls
```
> Listeaza nodurile din cluster. Deocamdata: un singur nod (masina curenta) cu statusul "Leader". Coloana `MANAGER STATUS` arata rolul nodului.

### Pasul 2: Salvare token si IP

```bash
SWARM_TOKEN=$(docker swarm join-token -q worker)
echo $SWARM_TOKEN
```
> Extrage token-ul de join si il salveaza intr-o variabila de mediu. `-q` = quiet (doar token-ul, fara textul explicativ).

```bash
SWARM_MASTER_IP=$(docker info --format '{{.Swarm.NodeAddr}}')
echo $SWARM_MASTER_IP
```
> Extrage IP-ul managerului. Workerii au nevoie de **token + IP + port** ca sa se conecteze la cluster.

### Pasul 3: Creare 3 workeri (containere dind)

```bash
for i in 1 2 3; do
  docker run -d --privileged --name worker-${i} --hostname=worker-${i} docker:dind
done
```
> Porneste 3 containere din imaginea `docker:dind` (Docker-in-Docker). Fiecare container are Docker Engine propriu si simuleaza o masina separata. `--privileged` e necesar pentru ca Docker sa poata rula in interiorul unui container (acces la kernel features).

```bash
docker ps
```
> Verifica ca cele 3 containere worker ruleaza. Fiecare are propriul daemon Docker inauntru.

### Pasul 4: Join workeri la Swarm

```bash
sleep 10
```
> Asteapta ca Docker Engine sa porneasca complet inauntrul containerelor dind (dureaza cateva secunde).

```bash
for i in 1 2 3; do
  docker exec worker-${i} docker swarm join --token ${SWARM_TOKEN} ${SWARM_MASTER_IP}:2377
done
```
> `docker exec` ruleaza comanda `docker swarm join` **inauntrul** fiecarui worker. Portul 2377 e portul standard pentru comunicarea intre nodurile Swarm.

### Pasul 5: Verificare cluster

```bash
docker node ls
```
> Acum ar trebui sa fie **4 noduri**: masina locala (Leader) + worker-1, worker-2, worker-3 (toate cu status Ready). Cluster-ul e functional.

---

## 5. Deploy stiva pe Swarm

O **stiva (stack)** este echivalentul Docker Compose, dar pentru Swarm — un grup de servicii definite in YAML, distribuite automat pe nodurile cluster-ului.

```bash
docker stack deploy -c docker-compose.swarm.yml lab2
```
> Lanseaza stiva "lab2" pe cluster. Swarm citeste fisierul YAML si distribuie serviciile pe nodurile disponibile. Spre deosebire de Compose (care ruleaza totul local), Swarm poate plasa containere pe **orice nod** din cluster.

```bash
docker service ls
```
> Listeaza serviciile Swarm (nu containerele individuale). Coloana `REPLICAS` arata cate instante ruleaza vs. cate sunt cerute (ex: `3/3` = toate 3 replicile sunt active).

```bash
docker stack ps lab2
```
> Arata **fiecare container** din stiva: pe ce nod ruleaza, in ce stare e, si de cat timp. Util pentru debugging — vezi daca vreun container a dat crash.

```bash
docker service logs -f lab2_web
```
> Log-uri agregate de la **toate replicile** serviciului web. In Swarm, log-urile vin de pe mai multe noduri — aceasta comanda le combina intr-un singur stream.

### Testare:

```bash
curl http://localhost:8080
```
> Returneaza pagina default nginx. Poti trimite cererea catre **orice nod** din cluster, nu doar cel pe care ruleaza containerul — Swarm foloseste **Routing Mesh** (un load balancer intern) care redirecteaza automat cererea catre un container activ.

---

## 6. Scalare servicii

**Scalarea** inseamna cresterea/scaderea numarului de instante ale unui serviciu. Swarm se ocupa automat de plasarea containerelor pe nodurile cu resurse disponibile.

```bash
docker service update --replicas 5 lab2_web
```
> Creste de la 3 la 5 replici. Swarm creeaza 2 containere noi si le plaseaza pe nodurile cu cel mai putin load (**scheduling automat**).

```bash
docker service ps lab2_web
```
> Verifica distributia: pe ce noduri ruleaza cele 5 replici. Swarm incearca sa le distribuie cat mai uniform.

```bash
docker service update --replicas 2 lab2_web
```
> Reduce la 2 replici. Swarm opreste 3 containere automat. In productie, scalarea se face si **automat** (pe baza de CPU/memorie), nu doar manual.

```bash
docker service ls
```
> Confirma ca serviciul are acum 2/2 replici active.

---

## 7. Secrets in Swarm

In productie, parolele, cheile API si alte credentiale **nu trebuie puse in cod sau in variabile de mediu vizibile**. Swarm ofera **Secrets** — un mecanism de stocare criptata, accesibil doar containerelor autorizate.

```bash
docker secret create db-password db-secret.txt
```
> Creeaza un secret din continutul unui fisier. Secretul e criptat in **Raft** (algoritmul de consens distribuit al Swarm) si stocat doar in memoria managerilor. Containerele il vad ca un fisier in `/run/secrets/db-password`.

```bash
docker secret ls
```
> Listeaza secretele existente. Observa: **nu poti vedea continutul** unui secret dupa creare — doar containerele carora le este atribuit il pot citi.

---

## 8. Cleanup

```bash
docker stack rm lab2
```
> Sterge stiva cu toate serviciile, containerele si retelele asociate.

```bash
docker stop worker-1 worker-2 worker-3
docker rm worker-1 worker-2 worker-3
```
> Opreste si sterge containerele dind (workerii simulati).

```bash
docker swarm leave --force
```
> Paraseste cluster-ul Swarm. `--force` e necesar pe manager — altfel Docker refuza (ai pierde cluster-ul).
