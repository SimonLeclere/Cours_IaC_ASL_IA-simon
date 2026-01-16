# 🧪 Exercice 09 — Déploiement avec ConfigMap comme volume
🎯 Objectif

Apprendre à injecter du contenu statique dans un pod via un ConfigMap monté comme volume, et observer comment NGINX lit automatiquement ce contenu.

📌 Contexte

Tu as déjà un Deployment NGINX avec 3 replicas.

Tu vas créer une ConfigMap contenant une page HTML, puis la monter dans tes pods pour que NGINX serve ce contenu.

Cela permet de séparer la configuration / contenu du déploiement et de mettre à jour le contenu sans recréer le Deployment.

## 🧩 Étapes
### Étape 1 — Créer la ConfigMap

<h1>Bienvenue sur mon NGINX version ConfigMap !</h1>
<p>Ce contenu est servi directement depuis une ConfigMap.</p>

Créer la ConfigMap :

kubectl create configmap web-html-config --from-file=index.html
kubectl get configmap web-html-config -o yaml

### Étape 2 — Déployer le Deployment

Créer le fichier web-deployment-configmap.yaml avec le contenu :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-logiciel
  template:
    metadata:
      labels:
        app: nginx-logiciel
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-storage
          mountPath: /usr/share/nginx/html/  # Nginx lira notre ConfigMap ici
      volumes:
      - name: html-storage
        configMap:
          name: web-html-config # Le nom de la ConfigMap créée à l'étape A
```
Appliquer le déploiement :

kubectl apply -f web-deployment-configmap.yaml

### Étape 3 — Vérifier le fonctionnement

Lister les pods :

kubectl get pods -l app=nginx-logiciel

Tester depuis un pod temporaire ou en NodePort :

kubectl run curlpod --rm -i --tty --image=curlimages/curl --restart=Never -- curl http://web-deployment:80

### Étape 4 — Mettre à jour la page HTML

Modifier le fichier index.html

Mettre à jour la ConfigMap :

kubectl create configmap web-html-config --from-file=index.html -o yaml --dry-run=client | kubectl apply -f -

Vérifier qu’au prochain redémarrage des pods, le nouveau contenu est pris en compte

kubectl rollout restart deployment web-deployment

Puis tester à nouveau avec curl depuis un pod temporaire.

✅ Résultat attendu

NGINX sert désormais le contenu stocké dans la ConfigMap

