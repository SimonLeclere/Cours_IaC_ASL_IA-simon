# 🧪 Exercice 03 — Services Kubernetes et accès réseau

## 🎯 Objectif
Comprendre comment Kubernetes expose une application à l’intérieur et à l’extérieur du cluster
en utilisant différents types de Services (`ClusterIP`, `NodePort`).

---

## 📌 Contexte
Vous avez déjà un déploiement `nginx` actif avec plusieurs pods.  
L’objectif est maintenant de **rendre l’application accessible depuis le cluster et depuis l’extérieur**, et de comprendre le rôle des différents types de Service.

---

## 🧩 Étapes

### Étape 1 — Créer un Service ClusterIP (interne)

kubectl expose deployment nginx --port=80 --type=ClusterIP  // peut-être il faut commencer par faire: kubectl delete svc nginx

Vérifiez :

kubectl get svc nginx

CLUSTER-IP est visible

Pas d’EXTERNAL-IP (service interne uniquement)

### Étape 2 — Tester l’accès interne depuis un pod

kubectl run curlpod --image=alpine --restart=Never -i --tty -- /bin/sh

Puis à l’intérieur du pod :

curl http://nginx:80

✔️ Vous devez voir la page NGINX s’afficher.

### Étape 3 — Créer un Service NodePort (externe)

kubectl expose deployment nginx --port=80 --type=NodePort

kubectl get svc nginx

Exemple de sortie:

| NAME  | TYPE     | CLUSTER-IP     | EXTERNAL-IP | PORT(S)      | AGE |
| ----- | -------- | -------------- | ----------- | ------------ | --- |
| nginx | NodePort | 10.100.117.217 | <none>      | 80:31078/TCP | 15m |

### Étape 4 — Tester l’accès depuis l’extérieur (votre poste de pilotage)

Depuis votre poste ou un autre terminal :

Exemple:

curl http://10.0.0.11:31078

✔️ Vous devez voir la page d’accueil NGINX.

✅ Résultat attendu

Service ClusterIP accessible uniquement interne au cluster

Service NodePort accessible depuis l’extérieur

Les pods répondent correctement via les deux types de Service




