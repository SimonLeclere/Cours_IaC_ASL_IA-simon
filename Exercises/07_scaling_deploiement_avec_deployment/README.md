# Exercice 07 — Déploiement et Scaling avec Deployment
🎯 Objectif

Apprendre à :

Créer un Deployment Kubernetes à partir d’un fichier YAML.

Comprendre le lien entre Deployment → ReplicaSet → Pods.

Gérer le scaling (augmentation ou diminution du nombre de pods).

📌 Contexte

Un Deployment permet de déclarer l’état désiré d’une application (nombre de replicas, image, labels, etc.).

Kubernetes s’occupe de créer et maintenir les pods correspondants.

Les labels et le selector permettent de relier le Deployment aux pods qu’il gère.

🧩 Étapes
### Étape 1 — Créer le fichier Deployment

Créer, dans un dossier séparé, un fichier web-deployment.yaml contenant :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-logiciel # Le lien entre le deployment et les pods
  template:
    metadata:
      labels:
        app: nginx-logiciel # L'étiquette collée sur chaque clone
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```
## Étape 2 — Déployer l’application

kubectl apply -f web-deployment.yaml

Vérifier que les pods sont bien créés :

kubectl get pods -l app=nginx-logiciel

✅ Résultat attendu : 3 pods en état Running

### Étape 3 — Exposer le Deployment via NodePort

kubectl expose deployment web-deployment --type=NodePort --port=80

Vérifier le service créé :

kubectl get svc web-deployment

### Étape 4 — Tester l’accès à l’application

Récupérer l’IP d’un nœud et le NodePort :

kubectl get nodes -o wide

kubectl get svc web-deployment

Tester l’accès depuis un pod curl ou directement depuis le nœud :

kubectl run curlpod --rm -i --tty --image=curlimages/curl --restart=Never -- curl http://NodeIP:NodePort

kubectl run curlpod --rm -i --tty --image=curlimages/curl --restart=Never -- curl http://CLUSTER-IP

curl  http://NodeIP:NodePort

✅ Résultat attendu : page d’accueil NGINX

### Étape 5 — Scaling du Deployment

Augmenter le nombre de pods à 5 :

kubectl scale deployment web-deployment --replicas=5

kubectl get pods -l app=nginx-logiciel

Réduire le nombre de pods à 2 :

kubectl scale deployment web-deployment --replicas=2

kubectl get pods -l app=nginx-logiciel

✅ Résultats attendus

Les pods créés par le Deployment correspondent aux replicas demandés.

Le service NodePort permet d’accéder à l’application depuis n’importe quel nœud du cluster.

Les commandes kubectl scale modifient dynamiquement le nombre de pods.

💡 Takeaway

Selector + Labels : crucial pour que le Deployment gère les bons pods.

Scaling : Kubernetes garantit que le nombre de pods correspond toujours à la déclaration du Deployment.

NodePort : utile pour tester depuis l’extérieur, mais pour du vrai production, préférez Ingress.
