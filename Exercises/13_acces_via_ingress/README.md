# 🎯 Objectifs pédagogiques

Comprendre le rôle d’un Ingress dans Kubernetes

Faire le lien entre Ingress → Service → Pods

Diagnostiquer un Ingress qui “ne fonctionne pas”

Vérifier la présence et le bon fonctionnement d’un Ingress Controller

Tester un accès HTTP par nom de domaine

Comprendre la différence entre ClusterIP et Ingress

### 📄 Fichier new-app-ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: new-php-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: example.lab
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: new-php-service
            port:
              number: 80
```

### Déploiement 

Appliquez le fichier :

kubectl apply -f new-app-ingress.yaml

Vérifiez que l’Ingress existe :

kubectl get ingress

Essayez d’accéder à l’application :

curl http://example.lab

👉 Constat attendu : ❌ ça ne fonctionne pas

1️⃣ Vérifier le Service

kubectl get svc new-php-service

kubectl describe svc new-php-service

👉 Le Service est bien de type ClusterIP

2️⃣ Tester sans Ingress

dans un terminal séparé : kubectl port-forward svc/new-php-service 8080:80

curl http://localhost:8080

👉 ✅ L’application fonctionne

Arrêtez le post-forward

➡️ Le problème ne vient pas de l’application

3️⃣ Vérifier l’Ingress Controller

kubectl get pods -n ingress-nginx

👉 Deux cas possibles :

❌ Namespace inexistant → aucun Ingress Controller

❌ Pods absents ou en erreur

4️⃣ Vérifier la résolution DNS

ping example.lab

👉 ❌ Le nom de domaine n’existe pas sur la machine cliente

###📝 Contexte

Vous avez déjà déployé votre application PHP et son service new-php-service. Vous allez maintenant la rendre accessible depuis votre poste de travail, en utilisant :

Port-Forwarding – connexion directe au service depuis votre machine.

Ingress Controller – connexion via un nom de domaine interne.

🔹 Étapes
1️⃣ Vérifier le service
kubectl get svc php-service

Exemple de sortie :

NAME	TYPE	CLUSTER-IP	PORT(S)

php-service	ClusterIP	10.102.200.10	80/TCP

⚠️ ClusterIP signifie que le service est interne au cluster.

2️⃣ Méthode 1 – Port-Forward (vous l'avez fait)

Forwarder le port 80 du service vers le port 8080 de votre machine :

kubectl port-forward svc/new-php-service 8080:80  (lancez dans un terminal séparé)

Testez dans un autre terminal ou navigateur :

curl http://localhost:8080 .. ou lynx http://localhost:8080 .. ou dans votre naviagteur


✅ Vous accédez directement au service via Kubernetes.

⚠️ Limitation : le tunnel fonctionne uniquement sur votre machine et temporairement.

3️⃣ Méthode 2 – Ingress Controller

Vérifier que l’Ingress Controller est déployé :

kubectl get pods -n ingress-nginx -o wide

kubectl get svc -n ingress-nginx

Identifier le node sur lequel tourne le pod ingress-nginx-controller :

kubectl get pods -n ingress-nginx -o wide

Exemple :

NAME	NODE

ingress-nginx-controller-6769cff97-vrtkw	k8s-worker2

Récupérer l’IP de ce node :

kubectl get nodes -o wide

Exemple :

NAME	INTERNAL-IP

k8s-worker2	10.0.0.12

Ajouter cette IP dans votre /etc/hosts pour le domaine utilisé dans l’Ingress (formation.lab) :

10.0.0.12 example.lab

Tester avec curl :

curl http://example.lab...ou lynx

✅ L’application est maintenant accessible via le nom de domaine interne géré par l’Ingress.


