🧪 Exercice 06 — Rolling Update ⭐⭐⭐

🎯 Objectif :
Apprendre à mettre à jour un déploiement Kubernetes sans interruption grâce aux rolling updates.

📌 Contexte

Les applications doivent souvent être mises à jour sans interrompre le service.

Kubernetes permet de mettre à jour les images d’un Deployment progressivement, un pod après l’autre.

🧩 Étapes

1️⃣ Vérifier le déploiement existant

kubectl get deployments
kubectl get pods

2️⃣ Mettre à jour l’image du déploiement

Exemple : mise à jour de NGINX vers une version plus récente

kubectl set image deployment/nginx nginx=nginx:1.24.0

3️⃣ Suivre la mise à jour

kubectl rollout status deployment/nginx

kubectl get pods

4️⃣ Revenir à l’ancienne version si nécessaire

kubectl rollout undo deployment/nginx

✅ Résultat attendu

Les pods sont mis à jour progressivement, sans interruption de service

Kubernetes gère automatiquement le remplacement des pods

Possibilité de revenir en arrière avec rollout undo
