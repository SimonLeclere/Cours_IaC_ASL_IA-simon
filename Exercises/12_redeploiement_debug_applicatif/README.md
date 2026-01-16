# 🎯 Objectifs pédagogiques

À la fin de cet exercice, l’étudiant saura :

Comprendre le lien entre ConfigMap et Pods

Identifier pourquoi une modification de ConfigMap ne redéploie pas automatiquement une application

Déboguer une erreur applicative liée à une base de données

Vérifier l’état réel des données dans MariaDB

Comprendre l’utilité de kubectl rollout restart

### 🧱 Contexte

Nous disposons :

d’un Deployment MariaDB (exo précédent)

d’un Service mariadb-service

d’un Secret contenant le mot de passe root

d’une base mabase contenant une seule table : utilisateurs

📄 Fichier php-app.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: new-php-code
data:
  index.php: |
    <?php
    $host = 'mariadb-service'; // On utilise le nom DNS du service créé à l'exo précédent
    $db   = 'mabase';
    $user = 'root';
    $pass = getenv('DB_PASSWORD');;   // Le mot de passe défini dans ton Secret

    try {
        $dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";
        $pdo = new PDO($dsn, $user, $pass);

        echo "<body style='font-family:sans-serif; text-align:center; padding-top:50px; background-color:#f0fff4;'>";
        echo "<h1 style='color:#2f855a;'>✅ Connexion Réussie !</h1>";
        echo "<p>L'application PHP communique bien avec MariaDB sur le port 3306.</p>";
        echo "<div style='border:1px solid #ccc; display:inline-block; padding:20px; border-radius:10px; background:white;'>";
        echo "<b>Infos Cluster :</b><br>";
        echo "Serveur DB : " . $host . "<br>";
        echo "IP du Pod PHP : " . $_SERVER['SERVER_ADDR'];

        $stmt = $pdo->query("SELECT contenu FROM posts");
        while ($row = $stmt->fetch()) {
         echo "<p>Contenu trouvé en base : <b>" . $row['contenu'] . "</b></p>";
        }
    } catch (PDOException $e) {
        echo "<body style='font-family:sans-serif; text-align:center; padding-top:50px; background-color:#fff5f5;'>";
        echo "<h1 style='color:#c53030;'>❌ Erreur de Connexion</h1>";
        echo "<p>Message : " . $e->getMessage() . "</p>";
        echo "</body>";
    }
    echo "</div></body>";
    ?>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-php-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: new-php-web
  template:
    metadata:
      labels:
        app: new-php-web
    spec:
      containers:
      - name: php
        image: php:8.0-apache
        # On installe l'extension PDO MySQL au démarrage (astuce pour image de base)
        command: ["sh", "-c", "docker-php-ext-install pdo pdo_mysql && apache2-foreground"]
        ports:
        - containerPort: 80
        volumeMounts:
        - name: code-volume
          mountPath: /var/www/html/index.php
          subPath: index.php
      volumes:
      - name: code-volume
        configMap:
          name: new-php-code
---
apiVersion: v1
kind: Service
metadata:
  name: new-php-service
spec:
  type: ClusterIP
  selector:
    app: new-php-web
  ports:
    - port: 80
      targetPort: 80
```

## Q1 — Observation
Déployer et l'application et vérifier les pods et services associés:

Que retourne l’application lorsqu’on exécute :

kubectl run curlpod --rm -it --image=curlimages/curl --restart=Never -- curl http://new-php-service

L’erreur concerne-t-elle :

Kubernetes ?

MariaDB ?

PHP ?

ou la configuration ?

## Q2 — Analyse du code PHP

Où est censé se trouver le mot de passe de la base ?

Quelle fonction PHP est utilisée pour le récupérer ?

Que se passe-t-il si la variable d’environnement n’existe pas ?

## Q3 — Analyse du Deployment

Le Secret mariadb-pass existe-t-il dans le cluster ?

Le Secret est-il injecté dans le Pod PHP ?

Quelle section du Deployment permettrait de l’injecter ?

## Q4 — Analyse base de données

Connectez-vous au Pod MariaDB :

Listez les tables de la base mabase

La table posts existe-t-elle ?

Quelle table existe réellement ?

### 🛠 Travail demandé

Corriger le Deployment PHP pour injecter le mot de passe

Corriger la requête SQL pour utiliser la bonne table

Redémarrer proprement l’application

Vérifier que les données s’affichent correctement


_________________________________________________________________________________________

✅ Correction (solution complète)
✔️ Étape 1 — Injection du Secret

Ajouter dans le container PHP :

env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: mariadb-pass
      key: password


➡️ Pourquoi ?
Parce que getenv("DB_PASSWORD") ne fonctionne que si la variable existe dans le Pod.

✔️ Étape 2 — Correction de la requête SQL

Dans la ConfigMap, remplacer :

$stmt = $pdo->query("SELECT contenu FROM posts");


par :

$stmt = $pdo->query("SELECT nom FROM utilisateurs");

🧱 Accéder au pod mariadb. Exemple:

kubectl exec -it mariadb-6bdb6b75c-zxxrv -- mariadb -uroot -p

✔️ Étape 3 — Redémarrage du Deployment

### ⚠️ kubectl apply ne suffit pas TOUJOURS avec une ConfigMap montée en volume.

Exécuter :

kubectl rollout restart deployment/new-php-app

### ➡️ Cela force la recréation des Pods et la relecture du code PHP.

✔️ Étape 4 — Vérification finale
kubectl run curlpod --rm -it --image=curlimages/curl --restart=Never -- curl http://new-php-service

###Résultat attendu :

Connexion réussie

Affichage des noms depuis la table utilisateurs

IP du Pod PHP affichée

Aucun message d’erreur

