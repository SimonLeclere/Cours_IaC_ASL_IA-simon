#!/bin/bash
#################################################################################
# Script d'installation des outils DevOps pour le poste de pilotage
# Usage: ./setup-workstation.sh
#################################################################################

set -e  # Arrêt en cas d'erreur

echo "🚀 Installation des outils DevOps..."

# Détection de l'OS
OS=$(uname -s)

#################################################################################
# 1. TERRAFORM
#################################################################################
echo ""
echo "📦 Installation de Terraform..."

if [ "$OS" = "Linux" ]; then
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y terraform
elif [ "$OS" = "Darwin" ]; then
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
fi

terraform version

#################################################################################
# 2. ANSIBLE
#################################################################################
echo ""
echo "📦 Installation d'Ansible..."

if [ "$OS" = "Linux" ]; then
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt install -y ansible
elif [ "$OS" = "Darwin" ]; then
    brew install ansible
fi

ansible --version

#################################################################################
# 3. KUBECTL
#################################################################################
echo ""
echo "📦 Installation de kubectl..."

if [ "$OS" = "Linux" ]; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
elif [ "$OS" = "Darwin" ]; then
    brew install kubectl
fi

kubectl version --client

#################################################################################
# 4. HELM (gestionnaire de packages Kubernetes)
#################################################################################
echo ""
echo "📦 Installation de Helm..."

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm version

#################################################################################
# 5. ARGOCD CLI (pour GitOps)
#################################################################################
echo ""
echo "📦 Installation d'ArgoCD CLI..."

if [ "$OS" = "Linux" ]; then
    curl -sSL -o /tmp/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 /tmp/argocd-linux-amd64 /usr/local/bin/argocd
    rm /tmp/argocd-linux-amd64
elif [ "$OS" = "Darwin" ]; then
    brew install argocd
fi

argocd version --client

#################################################################################
# 6. JQ (parsing JSON)
#################################################################################
echo ""
echo "📦 Installation de jq..."

if [ "$OS" = "Linux" ]; then
    sudo apt install -y jq
elif [ "$OS" = "Darwin" ]; then
    brew install jq
fi

jq --version

#################################################################################
# 7. Génération de clé SSH (si inexistante)
#################################################################################
echo ""
echo "🔑 Vérification de la clé SSH..."

if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Génération d'une nouvelle clé SSH..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "terraform-ansible-k8s"
else
    echo "✅ Clé SSH existante détectée"
fi

echo ""
echo "📋 Votre clé publique SSH (à ajouter au template Cloud-Init) :"
cat ~/.ssh/id_rsa.pub

#################################################################################
# FIN
#################################################################################
echo ""
echo "✅ Installation terminée !"
echo ""
echo "🔧 Prochaines étapes :"
echo "   1. Créer le dossier du projet : mkdir -p ~/k8s-proxmox-iac && cd ~/k8s-proxmox-iac"
echo "   2. Copier votre clé SSH dans le template Proxmox"
echo "   3. Configurer Terraform (fichier terraform.tfvars)"
