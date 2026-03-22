# Docker Lab 1 - Cheatsheet

---

## 1. Verificare instalare

Docker are o arhitectura **client-server**: clientul (CLI-ul `docker`) trimite comenzi catre server (Docker Engine/daemon). Ambele trebuie sa fie active.

```bash
docker version
```
> Afiseaza versiunea clientului si a serverului. Daca serverul nu apare, Docker Engine nu ruleaza.

```bash
docker container run hello-world
```
> Descarca imaginea `hello-world` de pe Docker Hub si ruleaza un container din ea. Daca vezi mesajul de succes, totul e configurat corect.

---

## 2. Imagini si containere de baza

**Imagine** = sablon read-only (ca o "clasa" in OOP). **Container** = instanta care ruleaza din acea imagine (ca un "obiect"). Dintr-o singura imagine poti crea oricate containere.

```bash
docker image pull alpine
```
> Descarca imaginea Alpine Linux (~7MB) de pe Docker Hub. Alpine e o distributie Linux minimala, ideala pentru containere datorita dimensiunii mici.

```bash
docker image ls
```
> Listeaza toate imaginile stocate local. Coloanele importante: `REPOSITORY` (numele), `TAG` (versiunea), `SIZE`.

```bash
docker container run alpine ls -l
```
> Creeaza un container din `alpine`, executa `ls -l` si se opreste imediat. Containerul exista doar cat timp comanda ruleaza — nu e o masina virtuala care sta pornita.

```bash
docker container run -it alpine
```
> Porneste un container **interactiv**: `-i` pastreaza STDIN deschis, `-t` aloca un pseudo-terminal. Practic, "intri" in container ca intr-un shell. Iesi cu `exit`.

```bash
docker container ls
```
> Listeaza doar containerele care ruleaza **acum**.

```bash
docker container ls -a
```
> Listeaza **toate** containerele, inclusiv cele oprite. Containerele oprite ocupa inca spatiu pe disc pana cand le stergi cu `docker rm`.

---

## 3. Container in background

In mod normal, containerul ocupa terminalul. Cu `-d` (detached), ruleaza in background — util pentru servere, baze de date, etc.

```bash
docker container run -d -it alpine
```
> Porneste containerul in background. Returneaza un **ID unic** (hash SHA256, trunchiat). Acest ID il folosesti ca sa interactionezi cu containerul.

```bash
docker attach <CONTAINER_ID>
```
> Te "ataseaza" la terminalul containerului care ruleaza deja. Atentie: `exit` opreste containerul! Alternativ, `Ctrl+P Ctrl+Q` te detaseaza fara sa-l opresti.

```bash
docker stop <CONTAINER_ID>
```
> Opreste containerul gracefully (trimite SIGTERM, asteapta 10s, apoi SIGKILL). Containerul ramane pe disc in starea "Exited".

```bash
docker rm <CONTAINER_ID>
```
> Sterge un container oprit de pe disc. Nu poti sterge un container care ruleaza (trebuie oprit mai intai, sau folosesti `docker rm -f`).

---

## 4. Build imagine custom (aplicatia Flask)

Un **Dockerfile** este o reteta pas-cu-pas care descrie cum se construieste o imagine: ce sistem de operare de baza, ce pachete sa instaleze, ce fisiere sa copieze, ce comanda sa ruleze la pornire.

Navigheaza in folderul cu Dockerfile + app.py (directorul curent al laboratorului).

```bash
docker build -t testapp .
```
> Construieste o imagine din Dockerfile-ul din directorul curent (`.`). Docker executa fiecare instructiune din Dockerfile ca un **layer** separat — layerele sunt cache-uite, deci rebuild-urile ulterioare sunt rapide daca nu s-a schimbat nimic.

```bash
docker images
```
> Verifica ca imaginea `testapp` apare in lista. Observa dimensiunea — include tot: OS de baza + dependinte + codul tau.

```bash
docker container run -p 8888:5000 testapp
```
> Ruleaza containerul si mapeaza portul. `-p 8888:5000` inseamna: cererile care vin pe portul **8888 al gazdei** sunt redirectionate catre portul **5000 din container** (unde asculta Flask). Deschide `http://127.0.0.1:8888` in browser.

```bash
docker container run -d -p 8888:5000 testapp
```
> Acelasi lucru, dar in background (`-d`). Terminalul ramane liber — asa rulezi servere in practica.

---

## 5. Publicare pe Docker Hub

**Docker Hub** este un registru public de imagini (ca un "GitHub pentru imagini Docker"). Oricine poate descarca imaginile publice. Conventia de nume: `username/repo:tag`.

```bash
docker login
```
> Autentificare pe Docker Hub. Credentialele sunt salvate local.

```bash
docker tag testapp <username>/idp:example
```
> Creeaza un **tag** (alias) pentru imagine in formatul `username/repo:tag`. Nu duplica imaginea — e doar o referinta noua catre aceleasi layere. Inlocuieste `<username>` cu username-ul tau de Docker Hub.

```bash
docker push <username>/idp:example
```
> Urca imaginea in registru. Docker trimite doar layerele care nu exista deja pe server — eficient datorita sistemului de layere. Inlocuieste `<username>` cu username-ul tau.

---

## 6. Networking - comunicare intre containere

Containerele sunt **izolate** implicit — nu pot comunica intre ele decat daca sunt in aceeasi retea Docker. Docker creeaza automat o retea `bridge` default, dar aceasta are limitari.

### 6a. Pornire containere

```bash
docker container run --name c1 -d -it alpine
docker container run --name c2 -d -it alpine
```
> Porneste 2 containere cu nume (`--name` le face usor de referit). Docker le pune automat in reteaua default `bridge`.

### 6b. In bridge default, containerele se vad prin IP dar NU prin nume

```bash
docker exec -it c1 ash
```
> `docker exec` ruleaza o comanda intr-un container **deja pornit** (spre deosebire de `docker run` care creeaza unul nou). `ash` e shell-ul din Alpine.

```
/ # ping -c2 c2
```
> ESUEAZA ("bad address") — reteaua default bridge **nu are DNS incorporat**, deci containerele nu se pot gasi prin nume. Ar merge doar prin IP, dar IP-urile se schimba.

```
/ # exit
```

### 6c. Scoatem containerele din bridge

```bash
docker network disconnect bridge c1
docker network disconnect bridge c2
```
> Demonstreaza izolarea totala: fara retea, containerele nu pot comunica deloc, nici macar prin IP.

### 6d. Cream o retea custom si le conectam

```bash
docker network create -d bridge c1-c2-bridge
```
> Creeaza o retea bridge **custom**. Diferenta critica: retelele custom au **DNS automat** — containerele se gasesc prin nume, nu doar prin IP. In practica, mereu folosesti retele custom.

```bash
docker network ls
```
> Listeaza toate retelele Docker. Vei vedea: `bridge` (default), `host`, `none`, si reteaua ta custom.

```bash
docker network connect c1-c2-bridge c1
docker network connect c1-c2-bridge c2
```
> Conecteaza ambele containere la reteaua custom. Un container poate fi in **mai multe retele** simultan.

### 6e. Acum se gasesc prin NUME

```bash
docker exec -it c1 ash
```
```
/ # ping -c2 c2
```
> FUNCTIONEAZA — DNS-ul retelei custom rezolva automat numele `c2` la IP-ul containerului. Asa comunica serviciile intre ele in Docker Compose (fiecare serviciu e accesibil prin numele sau).

```
/ # exit
```

---

## 7. Persistenta - volume

Containerele sunt **efemere** — cand le stergi, tot ce era inauntru dispare. **Volumele** sunt mecanismul Docker pentru date persistente: sunt stocate in afara containerului, pe masina gazda.

### 7a. FARA volum - datele se pierd

```bash
docker run --name demo1 -it alpine sh
```

```
/ # echo "salut studenti" > /mesaj.txt
/ # cat /mesaj.txt
```
> Creezi un fisier **in filesystem-ul containerului** (layer read-write de deasupra imaginii).

```
/ # exit
```

```bash
docker rm demo1
```
> Stergi containerul — inclusiv layerul read-write cu fisierul tau.

```bash
docker run --name demo1 -it alpine sh
```

```
/ # cat /mesaj.txt
```
> `No such file or directory` — containerul e **nou**, pornit de la zero din aceeasi imagine. Nu "mosteneste" nimic de la cel vechi.

```
/ # exit
```

```bash
docker rm demo1
```

### 7b. CU volum - datele raman

```bash
docker volume create datele-mele
```
> Creeaza un **volum Docker** — un director gestionat de Docker pe masina gazda, independent de orice container.

```bash
docker run --name demo2 -it -v datele-mele:/date alpine sh
```
> `-v datele-mele:/date` monteaza volumul in directorul `/date` din container. Tot ce scrii in `/date` ajunge de fapt in volum, nu in layerul containerului.

```
/ # echo "salut studenti" > /date/mesaj.txt
/ # cat /date/mesaj.txt
```
> Scrii fisierul **in volum**, nu direct in container.

```
/ # exit
```

```bash
docker rm demo2
```
> Stergi containerul, dar volumul ramane intact — nu apartine containerului.

```bash
docker run --name demo3 -it -v datele-mele:/date alpine sh
```
> Container **complet nou**, dar monteaza **acelasi volum**.

```
/ # cat /date/mesaj.txt
```
> `salut studenti` — datele au supravietuit! Volumul persista independent de ciclul de viata al containerelor. Asa se pastreaza datele bazelor de date in productie.

```
/ # exit
```

```bash
docker rm demo3
docker volume rm datele-mele
```
> Cleanup. `docker volume rm` sterge volumul definitiv — datele dispar.

---

## 8. Cleanup

```bash
docker stop $(docker ps -q)
```
> Opreste toate containerele active. `docker ps -q` returneaza doar ID-urile, care sunt pasate ca argumente la `docker stop`.

```bash
docker rm $(docker ps -aq)
```
> Sterge toate containerele (inclusiv cele oprite). `-a` = toate, `-q` = doar ID-uri.

```bash
docker system prune
```
> Curatenie generala: sterge containere oprite, retele nefolosite si imagini "dangling" (layere orfane). Recupereaza spatiu pe disc.
