## 🔐 Configurer SSH avec un fichier `config`

### 🛠️ Créer ou éditer le fichier de configuration SSH

```bash
nano ~/.ssh/config
➕ Ajouter la configuration suivante
# Configuration pour le cluster Kubernetes
Host k8s-master
    HostName 10.0.0.10
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_proxmox_templates
    StrictHostKeyChecking no

Host k8s-worker1
    HostName 10.0.0.11
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_proxmox_templates
    StrictHostKeyChecking no

Host k8s-worker2
    HostName 10.0.0.12
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_proxmox_templates
    StrictHostKeyChecking no

Host k8s-worker3
    HostName 10.0.0.13
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_proxmox_templates
    StrictHostKeyChecking no

# Configuration globale pour tous les nodes Kubernetes
Host 10.0.0.*
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_proxmox_templates
    StrictHostKeyChecking no

💾 Sauvegarder et corriger les permissions
chmod 600 ~/.ssh/config

✅ Utilisation simplifiée
# Au lieu de :
# ssh -i ~/.ssh/id_rsa_proxmox_templates ubuntu@10.0.0.10

ssh k8s-master

# Ou directement avec l’adresse IP
ssh 10.0.0.10
# Exemple avec kubectl

ssh k8s-master "kubectl get nodes"
ou plus simplement:
kubectl get nodes

