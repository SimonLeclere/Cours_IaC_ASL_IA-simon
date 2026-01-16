# 🧪 Exercice 10 — Déployer MariaDB avec stockage persistant
🎯 Objectifs pédagogiques

À la fin de cet exercice, vous devriez être capable de :

Déployer une base de données MariaDB dans Kubernetes

Utiliser un Secret pour gérer un mot de passe sensible

Mettre en place un stockage persistant via PV / PVC

Comprendre le rôle de nodeSelector avec un hostPath

Exposer la base via un Service interne (ClusterIP)

### 🧩 Étape A — Création du Secret

La base MariaDB nécessite un mot de passe root.

Pour des raisons de sécurité, celui-ci est stocké dans un Secret Kubernetes.

kubectl create secret generic mariadb-pass --from-literal=password=supersecret
  
Vérification :

kubectl get secrets

kubectl describe secret mariadb-pass

📌 Pourquoi un Secret ?

Évite d’écrire des mots de passe en clair dans les fichiers YAML

Permet une gestion séparée des données sensibles

### 🧩 Étape B — Création du PersistentVolume (PV)

Fichier mariadb-pv.yaml

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data-mariadb"
```
Application :

kubectl apply -f mariadb-pv.yaml

kubectl get pv

📌 Point important

hostPath crée le stockage localement sur le nœud

Ce type de volume est pédagogique, pas recommandé en production.

Le PersistentVolume utilise un hostPath, ce qui implique que le dossier ciblé doit exister sur le nœud hébergeant le Pod.
Comme le Deployment force l’exécution sur k8s-worker1, le répertoire /mnt/data-mariadb doit être créé manuellement sur ce nœud, avec les droits adaptés, avant le déploiement.

1️⃣ Se connecter sur le bon worker

ssh k8s-worker1

2️⃣ Créer le dossier

sudo mkdir -p /mnt/data-mariadb

sudo chmod 777 /mnt/data-mariadb

sudo chown -R 999:999 /mnt/data-mariadb

### 🧩 Étape C — Création du PersistentVolumeClaim (PVC)

Fichier mariadb-pvc.yaml :

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```
Application :

kubectl apply -f mariadb-pvc.yaml

kubectl get pvc

📌 Le PVC permet au pod de demander dynamiquement du stockage sans connaître le PV exact.

### 🧩 Étape D — Déploiement de MariaDB

Fichier mariadb-deploy.yaml :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      nodeSelector:
        kubernetes.io/hostname: k8s-worker1
      containers:
      - name: mariadb
        image: mariadb:10.6
        env:
        - name: MARIADB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-pass
              key: password
        - name: MARIADB_DATABASE
          value: mabase
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: storage
          mountPath: /var/lib/mysql
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: mariadb-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mariadb-service
spec:
  selector:
    app: mariadb
  ports:
    - port: 3306
      targetPort: 3306
```
Application :

kubectl apply -f mariadb-deploy.yaml

🔍 Vérifications

kubectl get pods -o wide

kubectl get svc

kubectl describe pod mariadb

Vérifier que :

Le pod est bien lancé sur k8s-worker1

Le PVC est bien monté

Le Service est en ClusterIP

🧪 Test de connexion à la base

Créer un pod client temporaire :

kubectl get secret mariadb-pass -o jsonpath="{.data.password}" | base64 -d

kubectl run mariadb-client --rm -it \
  --image=mariadb:10.6 \
  --env="MYSQL_PWD=supersecret" \
  --restart=Never -- \
  mariadb -h mariadb-service -u root

📌 MariaDB utilise automatiquement MYSQL_PWD si elle existe.

🧠 Point important
🔹 Le Secret est scopé au pod

Un Secret :

❌ n’est pas global au cluster

❌ n’est pas partagé automatiquement

Il doit être : monté ou injecté explicitement dans chaque pod

👉 Sécurité par défaut de Kubernetes

🧪 Vérification côté serveur (bonus)

kubectl exec -it deploy/mariadb -- env | grep MARIADB

Résultat attendu :

MARIADB_ROOT_PASSWORD=********

MARIADB_DATABASE=mabase

deploy/mariadb est un Deployment

kubectl exec attend un Pod

kubectl est censé :

résoudre le Deployment

trouver un Pod

s’y connecter

🔹 Toujours exécuter kubectl exec sur un Pod, pas un Deployment

1️⃣ Récupérer le nom exact du pod

kubectl get pods -l app=mariadb

Exemple de sortie :

mariadb-7c6c9b8d7f-abcde

2️⃣ Exécuter la commande correctement

kubectl exec -it mariadb-7c6c9b8d7f-abcde -- env | grep MARIADB

📌 À noter 

kubectl exec deploy/xxx peut fonctionner sur certaines versions,
mais ce n’est pas fiable et peut provoquer des erreurs internes.

👉 Bonne règle :

get / describe → Deployment, Service

logs / exec → Pod uniquement

🧠 important

Lors de l’utilisation de kubectl exec, la commande doit cibler un Pod et non un Deployment.
Dans certaines versions de kubectl, l’exécution directe sur un Deployment peut provoquer un panic interne du client (nil pointer dereference).
Il est donc recommandé de récupérer explicitement le nom du pod avant d’utiliser kubectl exec.

Vérifions que les données stockées dans MariaDB persistent après :

la suppression du Pod

le redémarrage du Deployment

Grâce à l’utilisation d’un PersistentVolume + PersistentVolumeClaim.
### 🅰️ Étape 1 – Se connecter à MariaDB depuis un Pod client

### 🅱️ Étape 2 – Créer une table et insérer des données

Dans le shell MariaDB :

USE mabase;

CREATE TABLE utilisateurs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(50),
  email VARCHAR(100)
);

INSERT INTO utilisateurs (nom, email)
VALUES
  ('Alice', 'alice@example.com'),
  ('Bob', 'bob@example.com');

SELECT * FROM utilisateurs;

### 🅲 Étape 3 – Supprimer le Pod MariaDB

kubectl get pods -l app=mariadb

kubectl delete pod <nom-du-pod-mariadb>

📌 Le Deployment recrée automatiquement un nouveau Pod.

kubectl get pods -l app=mariadb

kubectl get pods -l app=mariadb

### 🅳 Étape 4 – Vérifier que les données sont toujours présentes

Relancer le client MariaDB.Puis :

USE mabase;
SELECT * FROM utilisateurs;

### ✅ Les données doivent toujours être présentes.

🧠 Explication

Le Pod a été supprimé 👉 éphémère

Le volume (PersistentVolume) est resté 👉 persistant

Les données sont stockées dans :

/mnt/data-mariadb

Cet exercice montre que Kubernetes ne persiste pas les données par défaut.
La persistance est assurée uniquement via des volumes.
Même si un Pod est recréé, les données restent accessibles tant que le volume persistant existe.




