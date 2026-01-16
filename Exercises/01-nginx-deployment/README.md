# 🧪 Exercice 01 — Déployer une application de test sur Kubernetes

## 🎯 Objectif
Déployer une application simple (`nginx`) sur un cluster Kubernetes afin de vérifier
le bon fonctionnement du cluster, du réseau et des services.

---

## 📌 Contexte
Le cluster Kubernetes est opérationnel :
- Tous les nœuds sont en état `Ready`
- Le réseau (Flannel) est correctement déployé
- L’accès au cluster via `kubectl` est fonctionnel

Vous allez déployer votre **première application** sur le cluster.

---

## 🧩 Étapes

### Étape 1 — Créer un déploiement NGINX
Créer un déploiement `nginx` avec **3 réplicas** :

kubectl create deployment nginx --image=nginx --replicas=3

### Étape 2 — Vérifier les pods

Vérifier que les pods sont bien créés et en cours d’exécution :
kubectl get pods
### Étape 3 — Exposer l’application

Exposer le déploiement via un Service de type NodePort :
kubectl expose deployment nginx --port=80 --type=NodePort

### Étape 4 — Vérifier le service

Afficher les informations du service :
kubectl get svc nginx

### Étape 5 — Tester l’accès à l’application

Depuis votre navigateur ou votre terminal, accéder à l’application :
 curl http://10.0.0.11:31078
 
✔️ La page d’accueil NGINX doit s’afficher.

✅ Résultat attendu

Le déploiement nginx est présent

3 pods sont en état Running

Le service nginx est accessible depuis l’extérieur du cluster

🧠 Questions (optionnel)

Sur quels nœuds les pods nginx sont-ils déployés ?

Que se passe-t-il si vous supprimez un pod nginx ?

Quelle est la différence entre un Service ClusterIP et NodePort ?




✅ Réponses — Exercice 01

1️⃣ Sur quels nœuds les pods nginx sont-ils déployés ?

Les pods nginx sont déployés sur les nœuds workers du cluster :

kubectl get pods -o wide

Cette commande permet de voir :

le nom du pod

son adresse IP

le nœud (NODE) sur lequel il s’exécute

👉 Par défaut :

Le scheduler Kubernetes répartit les pods sur les workers disponibles

Le nœud control-plane n’héberge pas de pods applicatifs (sauf exception)

2️⃣ Que se passe-t-il si vous supprimez un pod nginx ?

Si vous supprimez un pod nginx :

kubectl delete pod <nom_du_pod>

Alors :

Kubernetes détecte que le nombre de pods est inférieur au nombre de réplicas demandé

Le Deployment recrée automatiquement un nouveau pod

Le cluster revient à 3 pods en état Running

👉 C’est le mécanisme de self-healing de Kubernetes.

Vous pouvez l’observer en temps réel avec :

kubectl get pods -w

3️⃣ Quelle est la différence entre un Service ClusterIP et NodePort ?

| Type de Service          | Description                                            | Accès              |
|--------------------------|--------------------------------------------------------|--------------------|
| `ClusterIP` (par défaut) | Service accessible uniquement à l’intérieur du cluster | Interne au cluster |
| `NodePort`              | Expose le service sur un port de chaque nœud           | Externe au cluster |


👉 Dans cet exercice :

NodePort est utilisé pour tester rapidement l’accès depuis l’extérieur

En production, on privilégie souvent Ingress + LoadBalancer
