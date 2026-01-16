# 🚀 Déploiement Kubernetes avec Ansible


Ce guide présente l’ordre d’exécution des scripts et des rôles Ansible pour déployer un cluster Kubernetes sur vos VMs créées à partir du template Proxmox.

📋 Prérequis

Les VMs doivent être créées et accessibles via SSH.

Votre clé SSH publique doit être ajoutée au template ou aux VMs.

Le tunnel réseau peut être créé si les VMs sont sur un réseau non directement accessible.

🔌 Tester la connectivité aux VMs

Avant de lancer vos playbooks, assurez-vous que les VMs sont joignables :

Créer un tunnel SSH vers le réseau des VMs (si nécessaire) :
sshuttle -r root@172.16.200.XX 10.0.0.0/24

Si toutes les VMs répondent avec pong, vous pouvez procéder au déploiement.

🛠️ Ordre d’exécution des playbooks

Les playbooks sont exécutés dans l’ordre suivant :
| Ordre | Playbook               | Description                                                                                         |
| ----- | ---------------------- | --------------------------------------------------------------------------------------------------- |
| 1     | `01-prepare-nodes.yml` | Prépare les VMs : mise à jour système, installation des packages de base et configuration initiale. |
| 2     | `02-install-k8s.yml`   | Installe Kubernetes (kubeadm, kubelet, kubectl) sur toutes les VMs.                                 |
| 3     | `03-init-master.yml`   | Initialise le nœud maître Kubernetes et configure le réseau du cluster.                             |
| 4     | `04-join-workers.yml`  | Ajoute les nœuds workers au cluster maître.                                                         |

✅ Recommandations

Testez toujours la connectivité avant d’exécuter les playbooks.

Exécutez les playbooks dans l’ordre indiqué.

Vérifiez les journaux Ansible pour détecter toute erreur avant de passer au playbook suivant.

Les tâches critiques sont idempotentes : vous pouvez relancer un playbook sans risque de casser la configuration existante.

🚀 ÉTAPE 1 : PRÉPARATION DES NODES

ansible-playbook -i inventory/hosts.yml playbooks/01-prepare-nodes.yml

**Lancez cette commande et observez l'exécution.**

**Ce qui va se passer :**
- Installation des paquets système
- Désactivation du swap
- Configuration des modules kernel
- Configuration des paramètres réseau

**Durée estimée : 2-3 minutes**
Si vous voyez failed=0 partout, c'est parfait ! ✅

🔧 ÉTAPE 2 : INSTALLATION DE KUBERNETES

Maintenant, installons Kubernetes sur tous les nodes :

ansible-playbook -i inventory/hosts.yml playbooks/02-install-k8s.yml

**Ce qui va se passer :**
- Installation de **containerd** (runtime de conteneurs)
- Installation de **kubeadm**, **kubelet**, **kubectl** version 1.28
- Configuration de containerd avec SystemdCgroup
- Verrouillage des versions

**⏱️ Durée estimée : 5-10 minutes** (téléchargement des paquets depuis Internet)

⚙️ ÉTAPE 3 : INITIALISATION DU MASTER

Maintenant, on va initialiser le cluster Kubernetes sur le master :

ansible-playbook -i inventory/hosts.yml playbooks/03-init-master.yml
```

**Ce qui va se passer :**
- 🚀 Initialisation du cluster avec `kubeadm init`
- 🌐 Installation du réseau **Flannel** (CNI)
- 🔑 Génération du **token de jointure** pour les workers
- 📁 Configuration de **kubectl** pour l'utilisateur ubuntu
- 💾 Sauvegarde de la commande de jointure dans `/tmp/k8s_join_command.sh`

**⏱️ Durée estimée : 3-5 minutes**

⚙️ ÉTAPE 3 : INITIALISATION DU MASTER

Maintenant, on va initialiser le cluster Kubernetes sur le master :

ansible-playbook -i inventory/hosts.yml playbooks/03-init-master.yml
```

**Ce qui va se passer :**
- 🚀 Initialisation du cluster avec `kubeadm init`
- 🌐 Installation du réseau **Flannel** (CNI)
- 🔑 Génération du **token de jointure** pour les workers
- 📁 Configuration de **kubectl** pour l'utilisateur ubuntu
- 💾 Sauvegarde de la commande de jointure dans `/tmp/k8s_join_command.sh`

**⏱️ Durée estimée : 3-5 minutes**

🔍 Point important :
À la fin, un fichier /tmp/k8s_join_command.sh sera créé sur votre poste avec la commande pour joindre les workers.Ce fichier (script) sera utilisé pour joindre les workers. Il est recommandé d’en conserver une copie de sauvegarde..

🔍  Vérifier le master depuis SSH (optionnel mais intéressant):

ssh ubuntu@10.0.0.10 "kubectl get nodes"

**Vous devriez voir :**

NAME         STATUS   ROLES           AGE   VERSION

k8s-master   Ready    control-plane   2m    v1.28.15

ÉTAPE 4 : JOINDRE LES WORKERS AU CLUSTER

C'est la dernière étape pour avoir un cluster complet !

ansible-playbook -i inventory/hosts.yml playbooks/04-join-workers.yml
```

**Ce qui va se passer :**
- 📝 Lecture de la commande de jointure depuis `/tmp/k8s_join_command.sh`
- 🔗 Jonction de **worker1**, **worker2**, **worker3** au cluster
- ⏳ Attente que tous les nodes soient **Ready**
- ✅ Affichage de la liste complète des nodes

**⏱️ Durée estimée : 2-3 minutes**

1. Vérifier tous les nodes depuis le master

ssh -i ~/.ssh/id_rsa_proxmox_templates ubuntu@10.0.0.10 "kubectl get nodes"

NAME          STATUS   ROLES           AGE     VERSION
k8s-master    Ready    control-plane   4m14s   v1.28.15
k8s-worker1   Ready    <none>          59s     v1.28.15
k8s-worker2   Ready    <none>          59s     v1.28.15
k8s-worker3   Ready    <none>          59s     v1.28.15

2. Vérifier les pods système

ssh -i ~/.ssh/id_rsa_proxmox_templates ubuntu@10.0.0.10 "kubectl get pods -A"
NAMESPACE      NAME                                 READY   STATUS    RESTARTS   AGE
kube-flannel   kube-flannel-ds-lbfvz                1/1     Running   0          2m54s
kube-flannel   kube-flannel-ds-lm5lt                1/1     Running   0          2m54s
kube-flannel   kube-flannel-ds-qzg4r                1/1     Running   0          5m52s
kube-flannel   kube-flannel-ds-t6cpf                1/1     Running   0          2m54s
kube-system    coredns-5dd5756b68-ggmhv             1/1     Running   0          5m51s
kube-system    coredns-5dd5756b68-jxznj             1/1     Running   0          5m51s
kube-system    etcd-k8s-master                      1/1     Running   0          6m7s
kube-system    kube-apiserver-k8s-master            1/1     Running   0          6m7s
kube-system    kube-controller-manager-k8s-master   1/1     Running   0          6m5s
kube-system    kube-proxy-6qm9g                     1/1     Running   0          5m52s
kube-system    kube-proxy-bnl68                     1/1     Running   0          2m54s
kube-system    kube-proxy-fs2vw                     1/1     Running   0          2m54s
kube-system    kube-proxy-vzznq                     1/1     Running   0          2m54s
kube-system    kube-scheduler-k8s-master            1/1     Running   0          6m5s

3. Récupérer le kubeconfig sur VOTRE poste
Pour gérer le cluster depuis votre machine (sans SSH) :
# Créer le répertoire .kube s'il n'existe pas
mkdir -p ~/.kube
# Copier le kubeconfig depuis le master
scp ubuntu@10.0.0.10:~/.kube/config ~/.kube/config
# Tester depuis votre poste
kubectl get nodes
kubectl get pods -A

# 🎯 RÉCAPITULATIF DE CE QUI A ÉTÉ FAIT

| Étape           | Commande           | Résultat                                |
|-----------------|------------------|----------------------------------------|
| ✅ Terraform    | `terraform apply` | 4 VMs créées                            |
| ✅ Ansible 1    | Préparation nodes | Swap désactivé, sysctl configuré       |
| ✅ Ansible 2    | Installation K8s  | Kubernetes 1.28.15 installé            |
| ✅ Ansible 3    | Init master       | Cluster initialisé, Flannel déployé    |
| ✅ Ansible 4    | Join workers      | 4 nodes dans le cluster                 |



