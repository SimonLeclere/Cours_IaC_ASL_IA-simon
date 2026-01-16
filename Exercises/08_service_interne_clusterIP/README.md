# 🧪 Exercice 08 — Services internes avec ClusterIP
🎯 Objectif

Apprendre à exposer un Deployment uniquement à l’intérieur du cluster avec un service de type ClusterIP, et vérifier que les pods du Deployment sont bien accessibles via ce service.

📌 Contexte

Ton Deployment web-deployment crée plusieurs pods NGINX avec le label app: nginx-logiciel.

Tu vas maintenant créer un service interne pour que les pods puissent communiquer entre eux ou avec d’autres pods sans exposer le service à l’extérieur.

🧩 Étapes

### Étape 1 — Créer le Service ClusterIP

Créer le fichier web-service.yaml avec le contenu suivant :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service-unique
spec:
  selector:
    app: nginx-logiciel # Il cherche les pods avec ce label (ceux de notre Deployment !)
  ports:
    - protocol: TCP
      port: 80          # Le port du Service
      targetPort: 80    # Le port du Pod
  type: ClusterIP       # IP interne uniquement
```

Déployer le service :

kubectl apply -f web-service.yaml

### Étape 2 — Vérifier le service

kubectl get svc

### Étape 3 — Tester la connectivité interne

Créer un pod temporaire pour tester l’accès au service :

kubectl run testpod --rm -i --tty --image=busybox --restart=Never -- /bin/sh

À l’intérieur du pod :

wget -qO- http://web-service-unique

✅ Résultat attendu : tu devrais voir la page d’accueil de NGINX.

### Étape 4 — Vérifier la correspondance avec les pods

Lister les endpoints du service :

kubectl get endpoints web-service-unique

Tu devrais voir les IPs des pods de ton Deployment.

Cela confirme que le service redirige le trafic vers tous les pods sélectionnés par le label app: nginx-logiciel

✅ Résumé

ClusterIP → service accessible uniquement à l’intérieur du cluster.

Le service sélectionne les pods via les labels.

Les pods peuvent communiquer entre eux via le service.

L’externalisation (NodePort ou LoadBalancer) n’est pas nécessaire pour la communication interne.
