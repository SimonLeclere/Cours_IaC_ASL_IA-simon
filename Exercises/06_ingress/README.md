# Exercice 07 — Ingress ⭐⭐⭐

🎯 Objectif :
Comprendre comment exposer plusieurs services Kubernetes via un point d’entrée unique avec Ingress.

📌 Contexte

NodePort permet d’exposer un service par port, mais si on a plusieurs services, c’est compliqué

Ingress permet de router le trafic HTTP/S vers différents services en fonction de l’URL ou du nom d’hôte

🧩 Étapes

### 1️⃣ Installer un contrôleur Ingress (ex : NGINX)

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

Ensuite vous pouvez vérifier que les ressources sont créées :

kubectl get pods -n ingress-nginx

kubectl get svc -n ingress-nginx

📌 Notes importantes

Ce manifest crée un namespace ingress-nginx et tous les objets nécessaires (Deployment, Service, RBAC…).

Si tu as des restrictions réseau (pas d’accès à Internet depuis le cluster), télécharge d’abord le YAML localement puis applique‑le.

🧪 Vérifier que l’installation a réussi

kubectl get all -n ingress-nginx

kubectl describe deployment ingress-nginx-controller -n ingress-nginx

 kubectl get svc -n ingress-nginx




Tu dois voir :

Un Deployment ingress-nginx-controller

Un Service exposé (LoadBalancer ou NodePort selon l’environnement)

| Name                               | Type         | Cluster-IP    | External-IP | Port(s)                    | Age |
| ---------------------------------- | ------------ | ------------- | ----------- | -------------------------- | --- |
| ingress-nginx-controller           | LoadBalancer | 10.102.117.34 | <pending>   | 80:31337/TCP,443:32176/TCP | 94m |
| ingress-nginx-controller-admission | ClusterIP    | 10.97.76.189  | <none>      | 443/TCP                    | 94m |

### Étape 2 — Créer un Ingress pour votre service Nginx

Créer le fichier example-ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```

kubectl apply -f example-ingress.yaml

kubectl get ingress

### ⚙️ Astuce pour tester votre Ingress localement

Pour que votre machine résolve le nom example.local :

Identifier le pod de l’Ingress controller et sur quel nœud il tourne :

kubectl get pods -n ingress-nginx -o wide

Récupérer l’IP interne du nœud :

kubectl get nodes -o wide

Ajouter la ligne correspondante dans votre /etc/hosts. par exemple:

10.0.0.12   example.local

Tester l’accès à votre service via l’Ingress :

curl http://example.local:31337

✅ Résultat attendu

L’Ingress route correctement les requêtes HTTP vers le service nginx.

Vous pouvez utiliser plusieurs hostnames et chemins pour router vers différents services sans multiplier les NodePorts.

