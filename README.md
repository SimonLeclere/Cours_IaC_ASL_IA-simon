# 🚀 Étape 1 : Préparation de l'Infrastructure (Template Proxmox)

Avant de déployer votre application avec Terraform ou Kubernetes, vous devez préparer l'image de base (template) sur votre nœud Proxmox.

Nous utilisons un script d'automatisation qui configure une image Ubuntu Noble 24.04 LTS optimisée avec cloud-init et le qemu-guest-agent.

## 📋 Prérequis

* Un accès SSH root à votre nœud Proxmox.
* Votre clé SSH publique configurée sur le nœud pour une connexion sans mot de passe.
* Les bridges réseaux `vmbr0` et `vmbr1` configurés sur Proxmox.

## 🛠️ Exécution du script de création

Le script `create_vm_template.sh` s'exécute depuis votre poste de travail local.
Il va générer une clé SSH dédiée pour vos futures VMs, la transférer sur Proxmox, et piloter la création du template à distance.

### Étapes

1. Rendez le script exécutable :

```bash
chmod +x create_vm_template.sh
```

2. Lancez la création du template en spécifiant le type de stockage cible (local-lvm ou NFS) :

```bash
# Exemple pour un stockage local-lvm
./create_vm_template.sh local-lvm

# Exemple pour un stockage NFS
./create_vm_template.sh nfs
```

## 🔍 Ce que fait le script

* **Génération de clé** : Crée une paire de clés SSH (`id_rsa_proxmox_templates`) sur votre machine pour sécuriser l'accès aux futures VMs.
* **Provisioning Cloud-Init** : Configure l'utilisateur par défaut (`ubuntu`), le mot de passe (`azerty`) et injecte votre clé publique.
* **Optimisation** : Installe automatiquement le `qemu-guest-agent` et effectue les mises à jour système (`apt upgrade`) au premier démarrage.
* **Réseau** : Prépare une configuration dual-stack (Management/Data) prête à être pilotée par Terraform.
* **⏱ Temps d'attente** : Lors du premier déploiement d'une VM basée sur ce template, prévoyez 5 à 10 minutes pour que Cloud-Init termine les mises à jour et l'installation des paquets.

## ⚠️ Recommandations importantes

* **Si vous disposez d’un partage NFS**, il est recommandé de créer le template dessus (`STORAGE='nfs'`) car :

  * L’import du disque est plus rapide.
  * Le clonage des VM depuis le template est également plus rapide.

* Le script **ne convertit pas automatiquement la VM en template**.
  Je préfère vérifier que la VM fonctionne correctement avant de la transformer manuellement en template via l’interface Proxmox ou la CLI :

```bash
qm template <VMID>
```

* Le template utilise DHCP par défaut sur les interfaces réseau.
* Les IP statiques doivent être définies par Terraform ou manuellement après le clonage.
* Le `qemu-guest-agent` sera automatiquement installé et activé.

---

# 🚀 Étape 2 : Préparer votre poste de pilotage DevOps

Avant de déployer vos templates et applications sur Proxmox/Kubernetes, il est recommandé d’installer tous les outils DevOps nécessaires sur votre poste de travail.

Nous fournissons un script `setup_workstation.sh` qui automatise l’installation de Terraform, Ansible, kubectl, Helm, ArgoCD CLI, `jq` et configure votre clé SSH.

## 📋 Prérequis

* Un poste Linux (Ubuntu/Debian) ou macOS.
* Accès à Internet pour télécharger les outils.
* Droits `sudo` pour installer les packages.

## 🛠️ Exécution du script

1. Rendez le script exécutable :

```bash
chmod +x setup_workstation.sh
```

2. Lancez le script :

```bash
./setup_workstation.sh
```

## 🔍 Ce que fait le script

* **Terraform** : Installation de la dernière version officielle.
* **Ansible** : Installation via le PPA officiel ou Homebrew.
* **kubectl** : Installation du client Kubernetes.
* **Helm** : Gestionnaire de packages pour Kubernetes.
* **ArgoCD CLI** : Pour piloter vos déploiements GitOps.
* **jq** : Outil de parsing JSON.
* **Clé SSH** : Vérifie si une clé `~/.ssh/id_rsa` existe ; sinon, elle est générée automatiquement avec 4096 bits et sans mot de passe.
* Affiche votre clé publique SSH à ajouter ensuite au template Cloud-Init.

---

<details>
<summary>📄 Contenu du script setup_workstation.sh</summary>

```bash
#!/bin/bash
set -e

echo "🚀 Installation des outils DevOps..."
OS=$(uname -s)

# Terraform
if [ "$OS" = "Linux" ]; then
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y terraform
elif [ "$OS" = "Darwin" ]; then
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
fi
terraform version

# Ansible
if [ "$OS" = "Linux" ]; then
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt install -y ansible
elif [ "$OS" = "Darwin" ]; then
    brew install ansible
fi
ansible --version

# kubectl
if [ "$OS" = "Linux" ]; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
elif [ "$OS" = "Darwin" ]; then
    brew install kubectl
fi
kubectl version --client

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# ArgoCD CLI
if [ "$OS" = "Linux" ]; then
    curl -sSL -o /tmp/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 /tmp/argocd-linux-amd64 /usr/local/bin/argocd
    rm /tmp/argocd-linux-amd64
elif [ "$OS" = "Darwin" ]; then
    brew install argocd
fi
argocd version --client

# jq
if [ "$OS" = "Linux" ]; then
    sudo apt install -y jq
elif [ "$OS" = "Darwin" ]; then
    brew install jq
fi
jq --version

# Clé SSH
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "terraform-ansible-k8s"
else
    echo "✅ Clé SSH existante détectée"
fi
cat ~/.ssh/id_rsa.pub

echo "✅ Installation terminée !"
echo "🔧 Prochaines étapes :"
echo "   1. Créer le dossier du projet : mkdir -p ~/k8s-proxmox-iac && cd ~/k8s-proxmox-iac"
echo "   2. Copier votre clé SSH dans le template Proxmox"
echo "   3. Configurer Terraform (fichier terraform.tfvars)"
```

</details>

