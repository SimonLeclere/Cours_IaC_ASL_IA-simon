# 🧪 Exercice 02 — Mise à l’échelle (Scaling) d’une application

## 🎯 Objectif
Apprendre à **mettre à l’échelle un déploiement** Kubernetes en modifiant le nombre de réplicas d’une application, et observer comment le cluster réagit automatiquement.

---

## 📌 Contexte
Dans l’exercice précédent, vous avez déployé un déploiement `nginx` avec **3 réplicas**.  
L’objectif maintenant est de :
- Augmenter le nombre de pods pour gérer plus de trafic
- Réduire le nombre de pods si nécessaire
- Observer la réaction du cluster

---

## 🧩 Étapes

### Étape 1 — Vérifier le nombre actuel de pods

bash
kubectl get pods
kubectl get deployment nginx

Vous devez voir 3 pods pour le déploiement nginx.

### Étape 2 — Augmenter le nombre de réplicas

Pour passer de 3 à 5 réplicas :

kubectl scale deployment nginx --replicas=5

Vérifiez ensuite :

kubectl get pods

kubectl get deployment nginx

👉 Vous devez maintenant voir 5 pods nginx en état Running.

### Étape 3 — Réduire le nombre de réplicas

Pour revenir à 2 réplicas :

kubectl scale deployment nginx --replicas=2

Vérifiez de nouveau que le nombre de pods correspond.

### Étape 4 — Observer le comportement automatique

Supprimez un pod au hasard :

kubectl delete pod <nom_du_pod>

Kubernetes va recréer immédiatement un nouveau pod pour maintenir le nombre de réplicas défini.

