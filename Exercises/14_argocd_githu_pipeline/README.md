# Exercice 14 – Déployer une application Flask + Postgres avec Argo CD (GitOps)
# 🎯 Objectifs pédagogiques

Construire et publier une image Docker

Déployer une application via Argo CD

Comprendre le rôle de chaque fichier Kubernetes

Mettre en œuvre une démarche GitOps

Observer la synchronisation automatique Argo CD → Cluster


### 🧩 A – Github & DockerHub

Avant de commencer, créez un nouveau dépôt GitHub pour votre projet Flask + PostgreSQL.

Connectez-vous à votre compte GitHub.

Cliquez sur New repository et donnez-lui un nom (ex. flask-app).

Assurez-vous que la structure du dépôt correspond à celle du modèle :

https://github.com/adell2024/mon-flask-app.git

🔐 Configuration des secrets GitHub pour Docker Hub

Avant de lancer le workflow GitHub Actions permettant de construire et publier l’image Docker, vous devez configurer les secrets nécessaires à l’authentification sur Docker Hub.

Allez sur votre dépôt GitHub

Cliquez sur Settings

Naviguez vers Secrets and variables → Actions

Ajoutez les deux secrets suivants :

DOCKERHUB_USERNAME : votre nom d’utilisateur Docker Hub

DOCKERHUB_TOKEN : un access token Docker Hub (à générer depuis votre compte Docker Hub)

⚠️ Important :
N’utilisez pas votre mot de passe Docker Hub. Vous devez créer un Access Token depuis
Docker Hub → Account Settings → Security → New Access Token.

Ces secrets seront automatiquement utilisés par le workflow GitHub Actions pour :

s’authentifier sur Docker Hub,

construire l’image Docker de l’application Flask,

publier l’image dans votre registre Docker Hub.

### 🧩 B– Installation d'ArgoCD sur le cluster K8S

Créer le namespace:

kubectl create namespace argocd

Installer ArgoCD (version stable):

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Attendre que tous les pods soient prêts:

kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

Vérifier que tous les pods sont en Running:
kubectl get pods -n argocd

Devrait montrer tous les pods en Running/Ready

Appliquer ce script: 
```bash
# 1. Mise à jour de l'application-controller (StatefulSet)
kubectl patch statefulset argocd-application-controller -n argocd --type strategic -p '
spec:
  template:
    spec:
      dnsPolicy: "None"
      dnsConfig:
        nameservers:
          - 10.96.0.10
          - 8.8.8.8
          - 8.8.4.4
        searches:
          - argocd.svc.cluster.local
          - svc.cluster.local
          - cluster.local
        options:
          - name: ndots
            value: "2"
'

# 2. Mise à jour du repo-server (Deployment)
kubectl patch deployment argocd-repo-server -n argocd --type strategic -p '
spec:
  template:
    spec:
      dnsPolicy: "None"
      dnsConfig:
        nameservers:
          - 10.96.0.10
          - 8.8.8.8
          - 8.8.4.4
        searches:
          - argocd.svc.cluster.local
          - svc.cluster.local
          - cluster.local
        options:
          - name: ndots
            value: "2"
'

# 3. Redémarrage des composants pour appliquer les changements
kubectl rollout restart statefulset argocd-application-controller -n argocd
kubectl rollout restart deployment argocd-repo-server -n argocd

# 4. Vérification du statut du déploiement
kubectl rollout status statefulset argocd-application-controller -n argocd
kubectl rollout status deployment argocd-repo-server -n argocd

# [!IMPORTANT] Vérifiez que l'IP 10.96.0.10 correspond bien à l'IP du service kube-dns ou coredns dans votre cluster:
(kubectl get svc -n kube-system).

```

### Récupération du mot de passe admin de ArgoCD:

kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d

### Vérifier que le pod argocd est capable de résoudre le domain github.com

par exemple, le mien ou le votre (rempalcer argocd argocd-repo-server-6d8f9bc87b-rwt4c) :
kubectl exec -n argocd argocd-repo-server-6d8f9bc87b-rwt4c --   git ls-remote https://github.com/adell2024/mon-flask-app.git

Defaulted container "argocd-repo-server" out of: argocd-repo-server, copyutil (init)

bade6e6aa901f04120ab28376b75bcbb7a5e0caa        HEAD

bade6e6aa901f04120ab28376b75bcbb7a5e0caa        refs/heads/main


### 🧩 C–  Déploiement

1️⃣ Déployer PostgreSQL

Créer le ConfigMap pour la configuration DB

kubectl apply -f k8s/postgres-config.yaml

Déployer la base PostgreSQL

kubectl apply -f k8s/postgres-db.yaml

Vérifier que le pod est bien en Running

kubectl get pods -l app=postgres

Vérifier le service
kubectl get svc postgres-service

2️⃣ Construire et publier l’image Docker Flask

(fait côté local, puis push sur DockerHub)

Se placer dans le dossier app
cd app

Construire l'image (exemple : DockerHub user "etu2026")
docker build -t etu2026/flask-app:latest .

Se connecter à DockerHub
docker login

Publier l'image
docker push etu2026/flask-app:latest

3️⃣ Déployer l’application Flask via Kubernetes

Déployer le déploiement Flask

kubectl apply -f k8s/flask-app.yaml

Vérifier les pods Flask
kubectl get pods -l app=flask

Vérifier le service Flask
kubectl get svc flask-service


4️⃣ Déployer l’Ingress (si vous utilisez un Ingress Controller NGINX)

Déployer l’Ingress
kubectl apply -f k8s/ingress.yaml

Vérifier les ingress
kubectl get ingress

Tester depuis un pod curl ou votre navigateur
kubectl run curlpod --rm -it --image=curlimages/curl --restart=Never -- curl http://flask.lab

⚠️ Pensez à ajouter flask.lab dans /etc/hosts pointant vers votre node ou LoadBalancer.

5️⃣ Déployer avec ArgoCD

Appliquer la définition de l’application ArgoCD

kubectl apply -f argo-app-definition.yaml

Vérifier que l'application est bien créée dans ArgoCD

kubectl get applications -n argocd

Forcer un sync si besoin

kubectl argo app sync flask-postgres-app

6️⃣ Vérifications utiles

Tous les pods

kubectl get pods -o wide

Services

kubectl get svc -o wide

Logs d’un pod Flask

kubectl logs <nom_du_pod_flask>

Logs d’un pod PostgreSQL

kubectl logs <nom_du_pod_postgres>

🔄 Mise à jour du déploiement via GitHub

Modifier le nombre de réplicas de l’application Flask directement dans le dépôt GitHub. Par exemple, dans k8s/flask-app.yaml :

spec:
  replicas: 2   # ← ancienne valeur

en :

spec:
  replicas: 4   # ← nouvelle valeur

Étapes à suivre

Commit et push les modifications sur GitHub :

git add k8s/flask-app.yaml
git commit -m "Augmentation des replicas de Flask à 4"
git push origin main

Vérification avec ArgoCD :

Lister les applications ArgoCD
kubectl get applications -n argocd

Vérifier l'état de synchronisation
kubectl get application flask-postgres-app -n argocd

L’état attendu après le push :

NAME	SYNC STATUS	HEALTH STATUS
flask-postgres-app	OutOfSync	Healthy

Attendre la synchronisation automatique :

Vérifier les pods Flask
kubectl get pods -l app=flask-app
