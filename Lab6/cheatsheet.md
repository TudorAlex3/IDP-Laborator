# Kubernetes Lab 6 - Cheatsheet

---

# PARTEA 0: Configurare mediu de lucru (o singura data)

Kubernetes nu vine instalat implicit. Avem nevoie de doua unelte: **kind** (creeaza clustere locale) si **kubectl** (trimite comenzi la cluster). Daca `kind --version` si `kubectl version --client` returneaza versiuni, poti sari la Partea 1.

---

## 0.1 Instalare kind

**kind** (Kubernetes IN Docker) simuleaza un cluster K8s folosind containere Docker — fiecare nod din cluster e un container.

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

```bash
kind --version
```
> Trebuie sa afiseze `kind version 0.27.0` sau similar.

---

## 0.2 Instalare kubectl

**kubectl** este CLI-ul Kubernetes — echivalentul comenzii `docker`. Toate comenzile catre cluster trec prin el.

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
```

```bash
kubectl version --client
```
> Trebuie sa afiseze versiunea (ex: `Client Version: v1.32.x`).

---

# PARTEA 1: Creare si rulare cluster

Un cluster Kubernetes e format din **Control Plane** (creierul — decide ce ruleaza unde) si **Worker Nodes** (unde ruleaza efectiv containerele). E similar cu Docker Swarm: Control Plane = nod manager, Workers = noduri worker.

---

## 1. Creare cluster kind

```bash
sudo service docker start
```

```bash
kind create cluster --config kind-config.yaml
```
> Creeaza un cluster cu 1 control-plane si 2 workers. Fisierul `kind-config.yaml` defineste structura. Echivalent Swarm: `docker swarm init` + `docker swarm join` pe 2 masini.

```bash
kubectl cluster-info
```
> Arata URL-ul API server-ului — clusterul e activ.

```bash
kubectl get nodes
```
> 3 noduri cu status **Ready** (1 control-plane, 2 workers). Echivalent: `docker node ls`.

```bash
kubectl get all
```
> Doar serviciul `kubernetes` (API server-ul). Inca n-am deployat nimic.

---

# PARTEA 2: Creare si rulare pod

**Pod** = cea mai mica unitate in Kubernetes. Contine 1 sau mai multe containere care impart aceeasi retea si storage. In practica, de obicei 1 pod = 1 container. Echivalent Swarm: un task.

---

## 2. Pod imperativ (din linia de comanda)

```bash
kubectl run my-nginx --image=nginx
```
> Creeaza un pod cu un container nginx. Echivalent: `docker run nginx`.

```bash
kubectl get pods
```
> Pod-ul `my-nginx` cu status Running.

```bash
kubectl get pods -o wide
```
> Detalii extra: pe ce nod ruleaza si ce IP intern are.

```bash
kubectl describe pod my-nginx
```
> Informatii complete: imagine, nod, events (pull, create, start), label-uri, etc. Util pentru debugging.

```bash
kubectl logs my-nginx
```
> Log-urile containerului nginx. Echivalent: `docker logs`.

```bash
kubectl exec -it my-nginx -- bash
```
> Intri in shell-ul containerului. Echivalent: `docker exec -it`. Scrie `exit` pentru a iesi.

```bash
kubectl delete pod my-nginx
```

---

## 3. Pod declarativ (din fisier YAML)

In Kubernetes lucram **declarativ** — scriem YAML-uri care descriu starea dorita, iar K8s o aplica. In loc de comenzi imperative (`kubectl run`), scriem ce vrem si aplicam cu `kubectl apply`.

Generam un YAML automat (fara sa cream pod-ul):

```bash
kubectl run nginx --image=nginx --dry-run=client -o yaml > nginx-pod.yaml
```
> `--dry-run=client` = genereaza YAML-ul fara sa creeze nimic. Util pentru a invata formatul.

```bash
cat nginx-pod.yaml
```
> Structura: `apiVersion`, `kind: Pod`, `metadata` (nume, label-uri), `spec` (containere).

```bash
kubectl apply -f nginx-pod.yaml
```
> Creeaza pod-ul din fisier. `apply` = "fa starea clusterului sa arate ca in fisier".

```bash
kubectl get pods
```

Port forward (acces din browser):

```bash
kubectl port-forward nginx 8080:80
```
> Mapam portul 8080 local la portul 80 al pod-ului. Deschide http://localhost:8080 — pagina nginx. Ctrl+C pentru a opri.

```bash
kubectl delete pod nginx
```

---

# PARTEA 3: Labels si selectors

**Label-urile** sunt perechi cheie-valoare atasate obiectelor K8s (pod-uri, servicii, etc.). **Selectorii** le folosesc pentru a gasi/grupa obiecte. Sunt fundamentale — ReplicaSets, Deployments si Services se bazeaza pe selectori ca sa stie care pod-uri le apartin.

---

## 4. Lucrul cu label-uri

Cream 3 pod-uri cu label-uri diferite:

```bash
kubectl run app1 --image=nginx --labels="app=web,env=prod"
kubectl run app2 --image=nginx --labels="app=web,env=dev"
kubectl run app3 --image=nginx --labels="app=api,env=prod"
```

```bash
kubectl get pods --show-labels
```
> Toate pod-urile cu label-urile lor.

### Filtrare cu selectors

```bash
kubectl get pods -l app=web
```
> Doar app1 si app2 (au label `app=web`).

```bash
kubectl get pods -l env=prod
```
> Doar app1 si app3 (au label `env=prod`).

```bash
kubectl get pods -l app=web,env=prod
```
> Doar app1 (are ambele label-uri).

```bash
kubectl get pods -l 'env!=prod'
```
> Doar app2 (`env=dev`, nu prod).

### Adaugare label

```bash
kubectl label pod app3 tier=backend
```

```bash
kubectl get pods --show-labels
```
> app3 are acum si label-ul `tier=backend`.

Cleanup:

```bash
kubectl delete pods app1 app2 app3
```

---

# PARTEA 4: ReplicaSets

**ReplicaSet** asigura ca un numar dorit de pod-uri identice ruleaza mereu. Daca un pod moare, ReplicaSet-ul il recreaza automat. Foloseste **selectors** ca sa stie care pod-uri ii apartin. Nu se foloseste direct in practica (Deployment-ul il creeaza automat), dar e important de inteles.

---

## 5. Creare ReplicaSet

```bash
cat > nginx-rs.yaml << 'EOF'
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx
EOF
```
> YAML-ul spune: "vreau 3 pod-uri cu label `app=nginx`, fiecare ruland imaginea nginx".

```bash
kubectl apply -f nginx-rs.yaml
```

```bash
kubectl get rs
```
> ReplicaSet-ul cu DESIRED=3, CURRENT=3, READY=3.

```bash
kubectl get pods --show-labels
```
> 3 pod-uri cu label `app=nginx`. Numele: `nginx-rs-XXXXX`.

### Self-healing (recreare automata)

```bash
kubectl delete $(kubectl get pods -l app=nginx -o name | head -1)
```
> Stergem manual un pod.

```bash
kubectl get pods
```
> Tot 3 pod-uri — ReplicaSet-ul a recreat automat pod-ul sters. Noul pod are alt nume.

### Scalare

```bash
kubectl scale rs nginx-rs --replicas=5
```

```bash
kubectl get pods
```
> 5 pod-uri acum.

```bash
kubectl scale rs nginx-rs --replicas=2
```

```bash
kubectl get pods
```
> 2 pod-uri — 3 au fost oprite.

```bash
kubectl delete rs nginx-rs
```

---

# PARTEA 5: Deployments

**Deployment** = **cel mai important obiect din Kubernetes**. Este echivalentul unui serviciu Docker Swarm. Gestioneaza automat ReplicaSets si ofera **rolling updates** (actualizare graduala) si **rollback** (revenire la versiunea anterioara).

Ierarhia: **Deployment** → creeaza un **ReplicaSet** → care creeaza **Pod-uri**.

---

## 6. Creare Deployment

```bash
cat > nginx-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.14.2
          ports:
            - containerPort: 80
EOF
```

```bash
kubectl apply -f nginx-deployment.yaml
```

```bash
kubectl get deploy
kubectl get rs
kubectl get pods
```
> Ierarhia: 1 Deployment → 1 ReplicaSet → 3 Pod-uri. Naming: `nginx-deploy` → `nginx-deploy-HASH` → `nginx-deploy-HASH-XXXXX`.

### Rolling Update

```bash
kubectl set image deployment nginx-deploy nginx=nginx:1.21.1
```
> Actualizeaza imaginea nginx. Pod-urile se inlocuiesc **gradual** (nu toate deodata) — rolling update.

```bash
kubectl rollout status deployment nginx-deploy
```
> "deployment successfully rolled out" — update-ul s-a terminat.

```bash
kubectl get rs
```
> 2 ReplicaSets — vechi (0 replici) si nou (3 replici). K8s pastreaza RS-ul vechi pentru rollback.

### Rollback

```bash
kubectl rollout history deployment nginx-deploy
```
> Istoricul reviziilor (revision 1, 2...).

```bash
kubectl rollout undo deployment nginx-deploy
```
> Revine la versiunea anterioara (nginx:1.14.2). Instant.

```bash
kubectl get rs
```
> ReplicaSet-ul vechi are iar 3 replici, cel nou are 0.

---

# PARTEA 6: ConfigMaps si Secrets

**ConfigMap** stocheaza configurari (variabile de mediu, fisiere config) **separat** de imaginea Docker. Asa poti folosi aceeasi imagine in dev si prod cu configurari diferite. **Secret** e la fel, dar pentru date sensibile (parole, token-uri) — encodate in base64.

Echivalent Swarm: `docker config` / `docker secret`.

---

## 7. ConfigMap

```bash
cat > db-configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-config
data:
  POSTGRES_USER: "admin"
  POSTGRES_DB: "books"
  APP_ENV: "production"
EOF
```

```bash
kubectl apply -f db-configmap.yaml
```

```bash
kubectl describe configmap db-config
```
> Cheile si valorile stocate.

## 8. Secret

```bash
kubectl create secret generic db-secret --from-literal=POSTGRES_PASSWORD=supersecret123
```
> Creeaza un Secret. In K8s, secretele sunt encodate base64 (NU criptate — nu e securitate reala fara componente extra).

```bash
kubectl get secret db-secret -o yaml
```
> Parola apare encodata base64.

## 9. Pod care foloseste ConfigMap + Secret

```bash
cat > test-config-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: test-config
spec:
  containers:
    - name: alpine
      image: alpine
      command: ["sleep", "3600"]
      envFrom:
        - configMapRef:
            name: db-config
        - secretRef:
            name: db-secret
EOF
```

```bash
kubectl apply -f test-config-pod.yaml
```

```bash
kubectl exec -it test-config -- env | grep -E "POSTGRES|APP_ENV"
```
> `POSTGRES_USER=admin`, `POSTGRES_DB=books`, `APP_ENV=production`, `POSTGRES_PASSWORD=supersecret123` — toate injectate din ConfigMap si Secret.

```bash
kubectl delete pod test-config
```

---

# PARTEA 7: Servicii

**Service** = cum expui pod-urile in retea. Fara un Service, pod-urile sunt accesibile doar prin IP intern (care se schimba la fiecare restart). Service-ul ofera un **DNS stabil** si **load balancing** automat intre pod-uri.

Echivalent Swarm: expunerea porturilor cu `ports:` si reteaua overlay.

---

## 10. Expunere Deployment prin Service

Deployment-ul `nginx-deploy` inca ruleaza (din pasul 6).

```bash
kubectl expose deployment nginx-deploy --port=80 --type=NodePort
```
> Creeaza un Service de tip **NodePort** — expune deployment-ul pe un port al nodului.

```bash
kubectl get svc
```
> Serviciul `nginx-deploy` cu port (ex: `80:31234/TCP`). 31234 = portul pe nod.

```bash
kubectl port-forward svc/nginx-deploy 8080:80
```
> http://localhost:8080 — nginx servit prin serviciu, cu load balancing intre cele 3 pod-uri. Ctrl+C.

## 11. Service declarativ (YAML)

```bash
cat > nginx-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
EOF
```

```bash
kubectl apply -f nginx-service.yaml
```

```bash
kubectl get svc
```
> Doua servicii: `nginx-deploy` (NodePort) si `nginx-svc` (ClusterIP). **ClusterIP** = doar intern — alte pod-uri pot accesa nginx prin `nginx-svc:80`, dar din afara clusterului nu e accesibil.

### Tipuri de servicii

| Tip | Acces | Echivalent Swarm |
|-----|-------|-----------------|
| **ClusterIP** | Doar intern (default) | retea overlay interna |
| **NodePort** | Expus pe port al nodului (30000-32767) | `ports: "8080:80"` |
| **LoadBalancer** | Load balancer extern (doar in cloud) | ingress mode |

---

# PARTEA 8: Cleanup

```bash
kubectl delete svc nginx-deploy nginx-svc 2>/dev/null
kubectl delete deploy nginx-deploy 2>/dev/null
kubectl delete configmap db-config 2>/dev/null
kubectl delete secret db-secret 2>/dev/null
```

```bash
kind delete cluster
```
> Sterge intregul cluster kind (toate containerele Docker care simulau nodurile).
