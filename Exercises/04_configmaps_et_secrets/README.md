# 🧪 Exercice 04 — ConfigMaps & Secrets

> 🎯 **Objectif :**  
> Apprendre à **gérer la configuration et les secrets** dans Kubernetes afin que les applications restent **découplées de leur configuration** et que les informations sensibles soient protégées.

---

## 📌 Contexte

- Les pods utilisent souvent des **fichiers de configuration**, **variables d’environnement**, ou **mots de passe**  
- Kubernetes propose deux objets principaux :
  1. **ConfigMap** → pour les informations de configuration non sensibles  
  2. **Secret** → pour les informations sensibles (mots de passe, clés API, certificats)

---

## 🧩 Étapes

### 1️⃣ Créer un ConfigMap

Exemple : configuration d’un message de bienvenue pour NGINX :

kubectl create configmap nginx-config \
  --from-literal=welcome_message="Bienvenue sur mon cluster Kubernetes !"

kubectl get configmap nginx-config -o yaml

### 2️⃣ Injecter le ConfigMap dans un pod

Créer le fichier pod-configmap.yaml :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-config-test
spec:
  containers:
  - name: nginx
    image: nginx
    env:
    - name: WELCOME_MESSAGE
      valueFrom:
        configMapKeyRef:
          name: nginx-config
          key: welcome_message
```


Déployer le pod :

kubectl apply -f pod-configmap.yaml

Vérifier la variable d’environnement :

kubectl exec -it nginx-config-test -- printenv WELCOME_MESSAGE


### 3️⃣ Créer un Secret

Exemple : stocker un mot de passe pour la base de données :

kubectl create secret generic db-secret \
  --from-literal=password='MonSuperMotDePasse'

kubectl get secret db-secret -o yaml

Les valeurs sont encodées en Base64 et ne sont pas visibles en clair.

### 4️⃣ Injecter le Secret dans un pod


Créer le fichier pod-secret.yaml 

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-secret-test
spec:
  containers:
  - name: nginx
    image: nginx
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
```
Déployer et vérifier :

kubectl apply -f pod-secret.yaml

kubectl exec -it nginx-secret-test -- printenv DB_PASSWORD

✅ Résultat attendu

Les ConfigMaps permettent de passer des informations de configuration aux pods

Les Secrets permettent de passer des informations sensibles en toute sécurité

Les pods récupèrent correctement ces valeurs via variables d’environnement ou volumes montés
