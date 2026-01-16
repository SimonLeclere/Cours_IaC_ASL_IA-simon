# 🚀 Déploiement avec Terraform

Ce dossier contient tous les fichiers nécessaires pour automatiser le déploiement de vos machines et de votre cluster Kubernetes sur Proxmox, en utilisant Terraform.

Terraform est utilisé ici pour :

- Créer automatiquement les VMs à partir des templates Proxmox que vous avez préparés.
- Configurer les interfaces réseau (Management/Data).
- Appliquer vos variables et configurations de manière déclarative.

---

## 📁 Structure du dossier

terraform/
├── main.tf # Point d'entrée principal
├── providers.tf # Définition des providers (Proxmox, etc.)
├── variables.tf # Variables globales
├── terraform.tfvars # Valeurs des variables pour votre environnement
├── outputs.tf # Valeurs calculées et exportées
└── modules/
└── k8s-node/
├── main.tf # Définition des VMs Kubernetes
├── variables.tf # Variables du module
├── outputs.tf # Valeurs exportées par le module
└── providers.tf # Providers spécifiques au module (optionnel)


---

## 🛠️ Prérequis

- Template Proxmox créé (voir Étape 1 dans le `README.md`).
- Clé SSH correctement configurée pour l’accès aux VMs.
- Terraform installé sur votre poste de pilotage (voir Étape 2 dans le `README.md`).
- Accès réseau vers votre cluster Proxmox.

---

## 🏁 Démarrage

1. **Initialiser Terraform**

Depuis le dossier `terraform` :

```bash
terraform init
Cela va télécharger les providers nécessaires et préparer votre environnement Terraform.

Planifier le déploiement
terraform plan
Vous pouvez vérifier quelles ressources seront créées, modifiées ou détruites.

Appliquer le plan
terraform apply
```

Confirmez la création en tapant yes. Terraform va alors provisionner vos VMs et appliquer les configurations réseau.

🔍 Bonnes pratiques

Modifiez terraform.tfvars pour adapter les IPs, noms de VM et ressources.

Utilisez les modules pour créer plusieurs types de nœuds (control, worker, etc.).

Toujours lancer terraform plan avant apply pour éviter des modifications inattendues.

Sauvegardez vos fichiers d’état (terraform.tfstate) en sécurité si vous travaillez en équipe.

Pour ajouter de nouvelles VMs ou clusters, créez des modules dédiés plutôt que de modifier directement le main.tf.
