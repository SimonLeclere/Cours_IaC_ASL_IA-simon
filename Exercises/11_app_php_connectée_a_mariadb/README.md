# 🧪 Exercice 11 – Application PHP connectée à MariaDB (Secrets existants)
🎯 Objectif

Déployer une application PHP qui :

communique avec MariaDB via un Service Kubernetes

utilise un Secret déjà existant pour le mot de passe

respecte les bonnes pratiques de sécurité (aucun secret en clair)

📌 Pré-requis

Les ressources suivantes existent déjà :

Deployment mariadb

Service mariadb-service

Secret mariadb-pass (clé password)

Database mabase

👉 On ne recrée rien ici (sauf le serveur web)

🅰️ Étape 1 – ConfigMap + Deployment + Service  : en un seul fichier. séparés par "----"

Le fichier php-app.yaml:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: php-code
data:
  index.php: |
    <?php
    $host = 'mariadb-service';
    $db   = 'mabase';
    $user = 'root';
    $pass = getenv('DB_PASSWORD'); // 🔐 Mot de passe depuis le Secret

    try {
        $dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";
        $pdo = new PDO($dsn, $user, $pass);

        echo "<body style='font-family:sans-serif; text-align:center; padding-top:50px; background-color:#f0fff4;'>";
        echo "<h1 style='color:#2f855a;'>✅ Connexion Réussie !</h1>";
        echo "<p>PHP communique correctement avec MariaDB.</p>";
        echo "<p><b>Service DB :</b> $host</p>";
        echo "<p><b>IP Pod PHP :</b> " . $_SERVER['SERVER_ADDR'] . "</p>";
        echo "</body>";
    } catch (PDOException $e) {
        echo "<body style='font-family:sans-serif; text-align:center; padding-top:50px; background-color:#fff5f5;'>";
        echo "<h1 style='color:#c53030;'>❌ Erreur de Connexion</h1>";
        echo "<p>" . $e->getMessage() . "</p>";
        echo "</body>";
    }
    ?>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: php-web
  template:
    metadata:
      labels:
        app: php-web
    spec:
      containers:
      - name: php
        image: php:8.0-apache
        command: ["sh", "-c", "docker-php-ext-install pdo pdo_mysql && apache2-foreground"]
        ports:
        - containerPort: 80
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-pass
              key: password
        volumeMounts:
        - name: code-volume
          mountPath: /var/www/html/index.php
          subPath: index.php
      volumes:
      - name: code-volume
        configMap:
          name: php-code
---
apiVersion: v1
kind: Service
metadata:
  name: php-service
spec:
  type: ClusterIP
  selector:
    app: php-web
  ports:
    - port: 80
      targetPort: 80
```

### 🅱️ Étape 2 : Déploiement

kubectl apply -f php-app.yaml

### 🅴 Étape 3 – Test

kubectl run curlpod --rm -it \
  --image=curlimages/curl \
  --restart=Never -- \
  curl http://php-service

### 🔹 Activité 1 – Compréhension de l’architecture (10 min)
Travail demandé

À partir des manifests fournis :

identifier :

le Pod MariaDB

le Pod PHP

les Services

les volumes

les Secrets et ConfigMaps

Réaliser un schéma simple de l’architecture (papier ou draw.io).

Validation

Expliquer :

Service vs Pod

ConfigMap vs Secret

### 🔹 Activité 2 – Vérifier la connectivité réseau (10 min)
Travail demandé

Depuis le Pod PHP :

kubectl exec -it <php-pod> -- bash
ping mariadb-service

Tester la résolution DNS Kubernetes.

Validation

L’élève explique pourquoi on utilise mariadb-service et non une IP.

### 🔹 Activité 3 – Création manuelle de données (15 min)
Travail demandé

Se connecter au Pod MariaDB :

kubectl exec -it mariadb-pod -- mysql -u root -p

Créer :
USE mabase;

CREATE TABLE posts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  content VARCHAR(150)
);

INSERT INTO posts (nom) VALUES ('blalbla'), ('etc etc');

Vérifier les données :

SELECT * FROM posts;

###🔹 Activité 4 – Tester la persistance des données (20 min)
Travail demandé

Supprimer le Pod MariaDB :

kubectl delete pod mariadb-pod

Attendre la recréation automatique du Pod.

Se reconnecter à MariaDB.

Vérifier que la table et les données existent toujours.

Identifier le rôle du volume.

###🔹 Activité 5 – Modifier le code PHP via ConfigMap (15 min)
Travail demandé

afficher : le nombre d’utilisateurs dans la table

Mettre à jour la ConfigMap :

kubectl apply -f php-app.yaml
kubectl rollout restart deployment php-app

Vérifier le résultat

###🔹 Activité 6 – Simulation de panne applicative (10 min)
Travail demandé

Supprimer un Pod PHP :

kubectl delete pod -l app=php-web

Observer :

kubectl get pods -w

Accéder à l’application pendant la suppression.

Expliquer le rôle de replicas: 2.

###🔹 Activité 7 – Débogage Kubernetes (bonus ⭐)
Travail demandé

Introduire volontairement une erreur :

mauvais nom de service

mauvais mot de passe DB

Identifier l’erreur via :

kubectl logs
kubectl describe pod

🧠 Questions de réflexion

Pourquoi ne pas mettre le mot de passe DB dans le code PHP ?

Quelle différence entre redémarrer un Pod et redéployer une application ?

Que se passe-t-il si le nœud Kubernetes tombe ?
