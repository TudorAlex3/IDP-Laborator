# Docker Lab 4 - Cheatsheet

---

# PARTEA I: Portainer

**Portainer** este o platforma web care permite administrarea vizuala a unui cluster Docker Swarm. In loc sa gestionezi totul din terminal cu comenzi, ai o interfata grafica unde vezi serviciile, le scalezi, le faci redeploy, gestionezi volume, retele, secrete — totul dintr-un dashboard. In plus, Portainer ofera **webhook-uri** care permit automatizarea deployment-ului (baza pentru CI/CD).

---

## 1. Pornire Docker si initializare Swarm

```bash
sudo service docker start
```
> Porneste Docker daemon-ul. Pe WSL2, Docker nu porneste automat — trebuie pornit manual dupa fiecare restart al sistemului.

Portainer ruleaza ca **serviciu de Swarm**, nu ca un container standalone. De aceea, avem nevoie de un cluster activ.

```bash
docker swarm init
```
> Initializeaza cluster-ul Swarm. Daca primesti eroare ca exista deja, e ok.

---

## 2. Deploy Portainer in Swarm

Portainer in Swarm are doua componente:
- **Agent** — ruleaza in mod **global** (pe fiecare nod din cluster). Colecteaza informatii despre containerele de pe acel nod si le trimite la Portainer.
- **Portainer** — aplicatia web propriu-zisa. Ruleaza doar pe **manager** (are nevoie de acces la API-ul Swarm).

```bash
docker stack deploy -c docker-compose.portainer.yml portainer
```
> Lanseaza stiva Portainer. `docker-compose.portainer.yml` contine definitia celor doua servicii, reteaua overlay si volumul persistent.

```bash
docker stack services portainer
```
> Verifica ca ambele servicii sunt active: agent (1/1 global) si portainer (1/1 replicated).

---

## 3. Acces si setup initial

Deschide in browser: **http://localhost:9000**

> La prima accesare, Portainer cere crearea unui cont admin:
> - Username: `admin`
> - Parola: minim 12 caractere
>
> Dupa login, apare pagina **Environment Wizard**:
> 1. Click pe **Docker Swarm** (din sectiunea "Connect to existing environments")
> 2. Click **Start Wizard**
> 3. Selecteaza **Socket**
> 4. Introdu un nume (orice, ex: `local`) si click **Connect**
> 5. Mergi la **Home** — apare environment-ul **"primary"**. Click pe el pentru a intra in dashboard.

---

## 4. Explorare interfata

Portainer ofera o vedere completa asupra cluster-ului, echivalenta cu toate comenzile `docker service/stack/volume/network` dar vizuala.

### Home
> Pagina **Home** arata environment-urile conectate. Apare **"primary"** cu statusul **Up**, numarul de stacks, servicii, containere, volume, noduri. Click pe el ca sa intri in gestiunea cluster-ului.

### Dupa click pe environment
> In meniul din stanga apar toate sectiunile:
> - **Stacks**: grupuri de servicii (echivalentul `docker stack`). Poti deploya stive noi direct din interfata
> - **Services**: toate serviciile din Swarm cu replici, porturi, imagine. Click pe un serviciu pentru detalii, logs, scalare
> - **Containers**: containerele care ruleaza
> - **Volumes**, **Networks**, **Secrets**: gestionare vizuala a resurselor Docker

---

## 5. Deploy aplicatie din Portainer UI

In loc de `docker stack deploy` din terminal, poti lansa o stiva direct din interfata Portainer.

> 1. In Portainer: **Stacks** -> **Add stack**
> 2. Nume: alegi un nume (ex: `myapp`)
> 3. Build method: **Web editor**
> 4. Lipesti continutul unui fisier `docker-compose.yml` in editor
> 5. Click **Deploy the stack**
>
> Stiva apare in lista, cu toate serviciile active. E exact ca `docker stack deploy`, dar vizual.

Alternativ, poti face deploy:
- Din **upload** (urci un fisier docker-compose.yml)
- Din **repository** (Portainer cloneaza un repo git si deployeaza)

**Nota**: Imaginile Docker trebuie sa existe deja (buildate sau descarcate). Swarm nu poate builda imagini — le foloseste gata facute.

---

## 6. Registries (registre de imagini)

Daca folosesti imagini private (de pe DockerHub privat, GitLab Registry, etc.), Portainer trebuie sa stie cum sa se autentifice.

> 1. **Settings -> Registries -> Add registry**
> 2. Alegi provider-ul (DockerHub, GitLab, Custom)
> 3. Introduci credentialele (username + token/parola)
>
> Dupa adaugare, Portainer poate face pull la imagini private cand deployezi stive.

---

## 7. Webhook-uri

Un **webhook** este un URL (endpoint HTTP) care, atunci cand e apelat, executa o actiune automata. In Portainer, webhook-ul unui serviciu face: **pull la cea mai noua versiune a imaginii + redeploy serviciu**.

> 1. **Services** -> click pe un serviciu care ruleaza deja in Swarm
> 2. Scroll la **Service webhook** -> toggle **ON**
> 3. Apare un URL de forma: `http://localhost:9000/api/webhooks/<id>`
> 4. Copiaza URL-ul

```bash
curl -XPOST http://localhost:9000/api/webhooks/<WEBHOOK_ID>
```
> Apelarea webhook-ului forteaza Portainer sa faca pull la imaginea cea mai noua si sa redeployeze serviciul. **Asta e mecanismul prin care CI/CD-ul va face deploy automat** — pipeline-ul de CI/CD apeleaza acest webhook dupa ce construieste si urca imaginea noua.

---

# PARTEA II: GitLab CI/CD

**CI/CD** (Continuous Integration / Continuous Deployment) automatizeaza intregul flux de la scrierea codului pana la rularea lui in productie.

**Fara CI/CD** (manual): modifici cod -> `docker build` -> `docker push` -> `docker stack deploy` -> repeti de fiecare data.

**Cu CI/CD** (automat): modifici cod -> `git push` -> **restul se face singur** (build, push imagine, redeploy).

---

## 8. Cum functioneaza — pas cu pas

1. Tu faci `git push` pe repo-ul unui microserviciu (ex: `auth-service`)
2. GitLab vede ca repo-ul are un fisier `.gitlab-ci.yml` (reteta pipeline-ului)
3. GitLab trimite job-ul la un **Runner** (container Docker care asteapta sa execute job-uri)
4. Runner-ul citeste `.gitlab-ci.yml` si executa etapele in ordine:
   - **Etapa build**: `docker build` (construieste imaginea) + `docker push` (o urca in GitLab Registry)
   - **Etapa deploy**: `curl -XPOST <webhook>` (apeleaza webhook-ul Portainer)
5. Portainer primeste apelul, face pull la imaginea noua si restarteaza serviciul in Swarm
6. **Gata** — codul nou ruleaza in cluster, fara nicio comanda manuala

---

## 9. Componentele CI/CD

| Componenta | Ce face |
|---|---|
| **GitLab** | Tine codul sursa (ca GitHub) |
| **Runner** | Container care executa pipeline-uri |
| **.gitlab-ci.yml** | Fisier in repo care descrie pasii pipeline-ului |
| **Registry** | Depozit de imagini Docker (GitLab Container Registry) |
| **Webhook Portainer** | URL care forteaza redeploy la un serviciu |

---

## 10. Structura recomandata

- **Fiecare microserviciu in propriul repository** pe GitLab
- Toate repo-urile intr-un **grup GitLab** comun (ca un folder)
- Fiecare repo are propriul `.gitlab-ci.yml` si propriul pipeline
- Cand faci push pe `auth-service`, doar pipeline-ul lui ruleaza. `booking-service` si `restaurant-service` nu sunt afectate

---

## 11. Setup GitLab Runner — pas cu pas

### 11.1. Creeaza cont pe gitlab.com (daca nu ai)

> Mergi pe https://gitlab.com si inregistreaza-te.

### 11.2. Creeaza un Personal Access Token

> Ai nevoie de token ca sa poti face `git push` din terminal.
>
> 1. Pe GitLab: click pe avatarul tau (colt dreapta sus) -> **Edit profile**
> 2. In meniul din stanga: **Access** -> **Personal access tokens**
> 3. Click **Add new token**
> 4. **Token name**: orice (ex: `lab4`)
> 5. **Expiration date**: o data in viitor
> 6. **Scopes**: bifeaza **api**
> 7. Click **Create personal access token**
> 8. **COPIAZA TOKEN-UL** si salveaza-l (apare o singura data!)

### 11.3. Creeaza un proiect pe GitLab

> 1. Pe GitLab: **"+"** -> **New project** -> **Create blank project**
> 2. **Project name**: numele microserviciului (ex: `api-service`)
> 3. **Visibility**: Public
> 4. **Debifează** "Initialize repository with a README"
> 5. Click **Create project**

### 11.4. Push codul pe GitLab

In directorul microserviciului (unde ai Dockerfile + codul):

```bash
git init
```
> Initializeaza un repo git local.

```bash
git remote add origin https://gitlab.com/<USERNAME>/<PROJECT_NAME>.git
```
> Conecteaza repo-ul local la GitLab. **Inlocuieste `<USERNAME>` si `<PROJECT_NAME>`.**

```bash
git add .
```
> Adauga toate fisierele in staging.

```bash
git commit -m "Initial commit"
```
> Creeaza commit-ul.

```bash
git push -u origin master
```
> Urca codul pe GitLab. La credentiale:
> - **Username**: username-ul tau de GitLab
> - **Password**: token-ul de la pasul 11.2 (NU parola contului!)

### 11.5. Instaleaza runner-ul

```bash
mkdir -p /srv/gitlab-runner/config
```

```bash
docker run -d --name gitlab-runner --restart always -v /srv/gitlab-runner/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest
```
> Porneste runner-ul ca container Docker.

### 11.6. Inregistreaza runner-ul

> Intai, ia token-ul de runner din GitLab:
> 1. Pe GitLab: repo-ul tau -> **Settings** -> **CI/CD** -> **Runners** -> **Expand**
> 2. Click **Create project runner** (sau **New project runner**)
> 3. **Tags**: scrie tag-urile dorite (ex: `idp, lab4`)
> 4. Restul lasa default -> click **Create runner**
> 5. Apare un **token** (incepe cu `glrt-...`). **Copiaza-l.**

Apoi in terminal:

```bash
docker run --rm -it -v /srv/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner register --url https://gitlab.com --token <TOKEN_COPIAT>
```
> **Inlocuieste `<TOKEN_COPIAT>` cu token-ul de mai sus.**
>
> Te intreaba mai multe. Raspunde asa:
> - **GitLab instance URL**: apasa **Enter** (lasa default)
> - **Name for the runner**: un nume (ex: `my-runner`)
> - **Executor**: scrie `docker`
> - **Default Docker image**: scrie `docker:latest`
>
> Trebuie sa apara: **Runner registered successfully.**

### 11.7. Configureaza runner-ul

```bash
sudo sed -i 's/privileged = false/privileged = true/' /srv/gitlab-runner/config/config.toml && sudo sed -i 's|volumes = \["/cache"\]|volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock"]|' /srv/gitlab-runner/config/config.toml
```
> Seteaza `privileged = true` (necesar pentru Docker-in-Docker) si adauga `docker.sock` la volumes.

```bash
docker restart gitlab-runner
```
> Reporneste runner-ul ca sa preia configuratia noua.

---

## 12. Fisierul .gitlab-ci.yml

Acesta e fisierul care spune runner-ului CE sa faca. Il pui in **root-ul repo-ului** (langa Dockerfile).

```yaml
stages:
    - build
    - deploy

docker-build:
    stage: build
    before_script:
        - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
    script:
        - docker build --pull -t "$CI_REGISTRY_IMAGE" .
        - docker push "$CI_REGISTRY_IMAGE"
    only:
        - master
    tags:
        - idp
        - lab4

deploy-service:
    stage: deploy
    script:
        - apk add --update curl
        - curl -XPOST http://<PORTAINER_IP>:9000/api/webhooks/<WEBHOOK_ID>
    only:
        - master
    tags:
        - idp
        - lab4
```

> **Ce face fiecare parte:**
> - `stages`: ordinea etapelor — intai `build`, apoi `deploy`
> - `docker-build`: login la GitLab Registry -> `docker build` -> `docker push` (imaginea ajunge in registry)
> - `deploy-service`: apeleaza webhook-ul Portainer -> Portainer redeployeaza serviciul cu imaginea noua
> - `only: master`: se executa doar cand faci push pe branch-ul master
> - `tags`: runner-ul care executa job-ul trebuie sa aiba aceste tag-uri (cele setate la inregistrare)
>
> **Inlocuieste:**
> - `<PORTAINER_IP>` cu IP-ul masinii unde ruleaza Portainer (sau `host.docker.internal` daca e local)
> - `<WEBHOOK_ID>` cu ID-ul webhook-ului din Portainer (pasul 7)
> - tag-urile cu cele pe care le-ai setat la inregistrarea runner-ului

### Push .gitlab-ci.yml pe GitLab

```bash
git add .gitlab-ci.yml
```

```bash
git commit -m "Add CI/CD pipeline"
```

```bash
git push
```

### Verificare

> 1. Pe GitLab: repo-ul tau -> **Build** -> **Pipelines**
> 2. Ar trebui sa vezi un pipeline cu statusul **Passed** (verde) sau **Running** (albastru)
> 3. Click pe pipeline pentru a vedea detaliile fiecarei etape

---

## 13. Alternativa: GitHub Actions

Daca folosesti **GitHub** in loc de GitLab, poti obtine acelasi flux CI/CD cu **GitHub Actions**. Nu ai nevoie sa instalezi un runner — GitHub ofera runnere gratuite in cloud.

### Structura

Fisierul pipeline-ului se pune in `.github/workflows/` (ex: `.github/workflows/deploy.yml`).

### Exemplu: `.github/workflows/deploy.yml`

```yaml
name: Build and Deploy

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v6
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:latest

  deploy:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Trigger Portainer webhook
        run: curl -XPOST ${{ secrets.PORTAINER_WEBHOOK_URL }}
```

> **Ce face fiecare parte:**
> - `on: push: branches: main`: se executa doar cand faci push pe branch-ul `main`
> - `build`: login la GitHub Container Registry (ghcr.io) -> `docker build` -> `docker push`
> - `deploy`: apeleaza webhook-ul Portainer (URL-ul e salvat ca secret in repo)
> - `needs: build`: job-ul `deploy` asteapta ca `build` sa termine cu succes
>
> **Setup necesar:**
> - Mergi pe GitHub: repo-ul tau -> **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret**
> - Adauga un secret `PORTAINER_WEBHOOK_URL` cu valoarea URL-ului webhook-ului din Portainer (pasul 7)
> - `GITHUB_TOKEN` este furnizat automat de GitHub Actions — nu trebuie configurat manual

### Verificare

> 1. Pe GitHub: repo-ul tau -> **Actions**
> 2. Ar trebui sa vezi un workflow run cu statusul **Success** (verde) sau **In progress** (galben)
> 3. Click pe run pentru a vedea detaliile fiecarui job

### Diferente fata de GitLab CI/CD

| | GitLab CI/CD | GitHub Actions |
|---|---|---|
| **Fisier pipeline** | `.gitlab-ci.yml` | `.github/workflows/*.yml` |
| **Runner** | Trebuie instalat manual | Oferit gratuit de GitHub |
| **Registry** | GitLab Container Registry | GitHub Container Registry (ghcr.io) |
| **Secrete** | Settings -> CI/CD -> Variables | Settings -> Secrets and variables -> Actions |

> Pentru mai multe detalii: [Documentatia oficiala GitHub Actions](https://docs.github.com/en/actions)

---

## 14. Testare flux complet (GitLab)

Dupa ce totul e configurat, testeaza fluxul:

1. Modifica ceva in cod (ex: adauga un endpoint nou in `server.js`)
2. Commit si push:

```bash
git add . && git commit -m "Update service" && git push
```

3. Mergi pe GitLab -> **Build** -> **Pipelines** si urmareste cum pipeline-ul ruleaza automat
4. Dupa ce pipeline-ul trece, serviciul din Swarm e actualizat automat

---

## 15. Cleanup

```bash
docker stack rm lab4
```
> Sterge stiva aplicatiei.

```bash
docker stack rm portainer
```
> Sterge stiva Portainer.

```bash
docker stop gitlab-runner 2>/dev/null; docker rm gitlab-runner 2>/dev/null
```
> Opreste si sterge runner-ul GitLab.

```bash
docker swarm leave --force
```
> Paraseste Swarm-ul.
