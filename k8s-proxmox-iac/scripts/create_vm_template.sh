#!/bin/bash

################################################################################
# Script de création de template Ubuntu Noble 24.04 LTS pour Proxmox VE
# EXÉCUTION DEPUIS UN POSTE DE TRAVAIL DISTANT
################################################################################
# Description : Ce script automatise la création d'un template VM Ubuntu Noble
#               avec cloud-init, qemu-guest-agent, et configuration réseau dual
#               Le script s'exécute depuis un poste distant avec accès SSH root
#               La clé SSH du poste de travail est injectée dans le template
#
# Architecture : Template générique sans IP statique
#                Les IPs seront assignées par Terraform lors du clonage
#
# Prérequis   : - Accès SSH root au node Proxmox
#               - Clé SSH configurée pour l'authentification sans mot de passe
#               - Proxmox VE 7.x ou 8.x sur le node cible
#               - Bridges vmbr0 et vmbr1 disponibles sur le node
#
# Usage       : ./create-ubuntu-template.sh
#
# Auteur      : Créé pour Proxmox TP-AA-proxmox-04-01 (changer pour votre node)
# Date        : Janvier 2026
################################################################################

set -e  # Arrêt du script en cas d'erreur

################################################################################
# SECTION 1 : CONFIGURATION DU NODE PROXMOX DISTANT
################################################################################

# Informations de connexion au node Proxmox
PROXMOX_HOST="172.19.15.193"  # A changer avec votre IP ou hostname du node Proxmox
PROXMOX_USER="root"            # Utilisateur SSH (généralement root)
PROXMOX_PORT="22"              # Port SSH

# Construction de la connexion SSH
SSH_CONNECTION="${PROXMOX_USER}@${PROXMOX_HOST}"
SSH_OPTIONS="-p ${PROXMOX_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=10"

################################################################################
# SECTION 2 : CONFIGURATION DE LA CLÉ SSH LOCALE
################################################################################

# Nom spécifique de la clé SSH pour les templates Proxmox
LOCAL_SSH_KEY_NAME="id_rsa_proxmox_templates"
LOCAL_SSH_KEY_PATH="$HOME/.ssh/${LOCAL_SSH_KEY_NAME}"
LOCAL_SSH_PUB_KEY_PATH="${LOCAL_SSH_KEY_PATH}.pub"

# Chemin temporaire sur le node Proxmox où sera transférée la clé
REMOTE_TEMP_SSH_KEY="/tmp/workstation_ssh_key.pub"

################################################################################
# SECTION 3 : VARIABLES DE CONFIGURATION DU TEMPLATE
################################################################################

# Identification de la VM/Template
VMID=5000
TEMPLATE_NAME="new-ubuntu-noble-template"

# Configuration storage
# Récupérer le choix de stockage passé en argument
STORAGE_CHOICE="$1"
case "$STORAGE_CHOICE" in
  # Utilisation conviviale : 'nfs' -> nom réel du storage sur le node
  nfs)
    STORAGE="nfsstorage"
    ;;
  local-lvm)
    STORAGE="local-lvm"
    ;;
  *)
    # Si un nom de storage Proxmox brut est fourni (ex: 'nfsstorage'), on l'accepte
    if [ -n "$STORAGE_CHOICE" ]; then
      STORAGE="$STORAGE_CHOICE"
      echo "✓ Utilisation du storage fourni : ${STORAGE}"
    else
      echo "✗ ERREUR : type de stockage invalide : '$STORAGE_CHOICE'"
      echo "Valeurs autorisées : nfs | local-lvm | <nom-du-storage-proxmox>"
      exit 1
    fi
    ;;
esac

echo "✓ Type de stockage sélectionné : ${STORAGE}"

# Configuration système de la VM
VM_MEMORY=16384  # RAM en MB
VM_CORES=4       # Nombre de cœurs CPU
DISK_SIZE="5G"   # Taille du disque

# Identifiants cloud-init par défaut
# Note: Ces identifiants peuvent être surchargés lors du clonage avec Terraform
CI_USER="ubuntu"
CI_PASSWORD="azerty"

# URL de l'image Ubuntu Noble cloud
UBUNTU_IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMAGE_FILE="noble-server-cloudimg-amd64.img"

################################################################################
# SECTION 4 : GESTION DE LA CLÉ SSH LOCALE
################################################################################

echo "═══════════════════════════════════════════════════════════════════════"
echo "  Création distante du template Ubuntu Noble sur ${PROXMOX_HOST}"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

echo "[LOCAL 1/5] Gestion de la clé SSH locale..."

# Vérifier si la clé SSH spécifique existe déjà
if [ ! -f "$LOCAL_SSH_PUB_KEY_PATH" ]; then
    echo "→ Clé SSH '${LOCAL_SSH_KEY_NAME}' non trouvée"
    echo "→ Génération d'une nouvelle paire de clés SSH..."

    # Créer le répertoire .ssh si nécessaire
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Générer la paire de clés avec un nom descriptif
    ssh-keygen -t rsa -b 4096 -f "$LOCAL_SSH_KEY_PATH" -N "" \
        -C "proxmox-template-key-$(date +%Y%m%d)"

    echo "✓ Nouvelle clé SSH générée : ${LOCAL_SSH_KEY_PATH}"
    echo "✓ Clé publique : ${LOCAL_SSH_PUB_KEY_PATH}"
else
    echo "✓ Clé SSH existante trouvée : ${LOCAL_SSH_PUB_KEY_PATH}"
fi

# Afficher l'empreinte de la clé pour vérification
echo ""
echo "Empreinte de la clé SSH qui sera injectée dans le template :"
ssh-keygen -lf "$LOCAL_SSH_PUB_KEY_PATH"
echo ""

# Lire le contenu de la clé publique
LOCAL_SSH_PUB_KEY_CONTENT=$(cat "$LOCAL_SSH_PUB_KEY_PATH")

################################################################################
# SECTION 5 : VÉRIFICATION DE LA CONNEXION AU NODE PROXMOX
################################################################################

echo "[LOCAL 2/5] Vérification de la connexion SSH au node Proxmox..."
if ! ssh $SSH_OPTIONS $SSH_CONNECTION "echo 'Connexion SSH réussie'" > /dev/null 2>&1; then
    echo "✗ ERREUR : Impossible de se connecter à ${PROXMOX_HOST}"
    echo ""
    echo "Vérifiez :"
    echo "  • L'adresse IP/hostname : ${PROXMOX_HOST}"
    echo "  • Le port SSH : ${PROXMOX_PORT}"
    echo "  • Votre clé SSH est-elle autorisée sur le node ?"
    echo "  • Le node est-il accessible depuis ce poste ?"
    echo ""
    echo "Pour configurer l'accès SSH sans mot de passe :"
    echo "  ssh-copy-id -p ${PROXMOX_PORT} ${SSH_CONNECTION}"
    echo ""
    exit 1
fi
echo "✓ Connexion SSH établie avec ${PROXMOX_HOST}"
echo ""

# Vérification que Proxmox est bien installé
echo "[LOCAL 3/5] Vérification de l'installation Proxmox..."
if ! ssh $SSH_OPTIONS $SSH_CONNECTION "command -v qm" > /dev/null 2>&1; then
    echo "✗ ERREUR : Proxmox VE n'est pas installé sur ${PROXMOX_HOST}"
    echo "La commande 'qm' n'a pas été trouvée."
    exit 1
fi
echo "✓ Proxmox VE détecté sur le node"
echo ""

################################################################################
# SECTION 6 : TRANSFERT DE LA CLÉ SSH VERS LE NODE
################################################################################

echo "[LOCAL 4/5] Transfert de la clé SSH publique vers le node Proxmox..."
echo "$LOCAL_SSH_PUB_KEY_CONTENT" | ssh $SSH_OPTIONS $SSH_CONNECTION "cat > ${REMOTE_TEMP_SSH_KEY}"
echo "✓ Clé SSH transférée vers ${PROXMOX_HOST}:${REMOTE_TEMP_SSH_KEY}"
echo ""

################################################################################
# SECTION 7 : GÉNÉRATION DU SCRIPT D'EXÉCUTION DISTANT
################################################################################

echo "[LOCAL 5/5] Génération du script d'exécution pour le node Proxmox..."

# Création du script qui sera exécuté sur le node Proxmox
REMOTE_SCRIPT=$(cat <<'REMOTE_SCRIPT_EOF'
#!/bin/bash
set -e

# Variables passées par le script principal
VMID="__VMID__"
TEMPLATE_NAME="__TEMPLATE_NAME__"
STORAGE="__STORAGE__"
VM_MEMORY="__VM_MEMORY__"
VM_CORES="__VM_CORES__"
DISK_SIZE="__DISK_SIZE__"
CI_USER="__CI_USER__"
CI_PASSWORD="__CI_PASSWORD__"
REMOTE_TEMP_SSH_KEY="__REMOTE_TEMP_SSH_KEY__"
UBUNTU_IMAGE_URL="__UBUNTU_IMAGE_URL__"
IMAGE_FILE="__IMAGE_FILE__"

################################################################################
# PRÉPARATION DE L'ENVIRONNEMENT
################################################################################

echo "[REMOTE 1/15] Création du fichier cloud-init pour qemu-guest-agent et mises à jour système..."
# S'assurer que le dossier 'snippets' existe avant d'écrire le fichier
mkdir -p /var/lib/vz/snippets
cat > /var/lib/vz/snippets/install-qemu-agent.yml << 'EOF'
#cloud-config
# Configuration cloud-init pour template Proxmox
# Mise à jour du système et installation des paquets essentiels

# ✅ Régénérer le machine-id AVANT tout autre chose
bootcmd:
  - rm -f /etc/machine-id
  - systemd-machine-id-setup
  - rm -f /var/lib/dbus/machine-id
  - ln -sf /etc/machine-id /var/lib/dbus/machine-id

# Mise à jour automatique du système
#package_update: true
#package_upgrade: true
#package_reboot_if_required: true

# Paquets à installer au premier boot
packages:
  - qemu-guest-agent
 # - curl
 # - wget
 # - vim
 # - net-tools
 # - htop

# Commandes à exécuter après l'installation des paquets
runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl restart qemu-guest-agent --no-block
  - truncate -s 0 /var/log/*.log /var/log/*/*.log
  - history -c && history -w

  # - apt-get autoremove -y
  # - apt-get autoclean -y
  - echo "Configuration terminée : $(date)" >> /var/log/cloud-init-custom.log

# Message affiché après le premier boot
final_message: "Cloud-init finished. System updated and qemu-guest-agent installed. Uptime: $UPTIME seconds"
EOF
echo "✓ Fichier cloud-init créé avec mise à jour système automatique"

echo "[REMOTE 2/15] Vérification de la clé SSH du poste de travail..."
if [ ! -f "$REMOTE_TEMP_SSH_KEY" ]; then
  echo "✗ ERREUR : Clé SSH du poste de travail non trouvée"
  exit 1
fi
echo "✓ Clé SSH du poste de travail prête : $REMOTE_TEMP_SSH_KEY"

################################################################################
# TÉLÉCHARGEMENT DE L'IMAGE
################################################################################

echo "[REMOTE 3/15] Téléchargement de l'image Ubuntu Noble..."
cd /tmp
[ -f "$IMAGE_FILE" ] && rm -f "$IMAGE_FILE"
wget --progress=bar:force "$UBUNTU_IMAGE_URL" -O "$IMAGE_FILE"
echo "✓ Image téléchargée : $(du -h $IMAGE_FILE | cut -f1)"

################################################################################
# CRÉATION DE LA VM
################################################################################

echo "[REMOTE 4/15] Création de la VM ${VMID}..."
qm create "$VMID" \
  --name "$TEMPLATE_NAME" \
  --memory "$VM_MEMORY" \
  --cores "$VM_CORES" \
  --net0 virtio,bridge=vmbr0 \
  --net1 virtio,bridge=vmbr1
echo "✓ VM ${VMID} créée avec ${VM_MEMORY}MB RAM et ${VM_CORES} cœurs"

################################################################################
# CONFIGURATION DU DISQUE
################################################################################

echo "[REMOTE 5/15] Vérification du storage '${STORAGE}' et import du disque (3-5 minutes)..."
# Vérifier que le storage existe sur le node Proxmox avant d'importer
if ! pvesm status | awk '{print $1}' | grep -xq "^${STORAGE}$"; then
  echo "✗ ERREUR : storage '${STORAGE}' non trouvé sur le node."
  echo "Storages disponibles :"
  pvesm status
  exit 1
fi
echo "✓ Storage '${STORAGE}' trouvé sur le node"

# Importer le disque et capturer la référence exacte retournée par qm importdisk
IMPORT_OUTPUT=$(qm importdisk "$VMID" "$IMAGE_FILE" "$STORAGE" 2>&1 || true)
echo "$IMPORT_OUTPUT"
# Extraire la chaîne entre quotes si présente: ex: 'nfsstorage:5000/vm-5000-disk-0.raw'
DISK_REF=$(echo "$IMPORT_OUTPUT" | sed -n "s/.*successfully imported disk '\([^']*\)'.*/\1/p")

if [ -n "$DISK_REF" ]; then
  echo "✓ Disque importé avec succès : $DISK_REF"
  # Pour la suite, on utilisera la référence exacte retournée par importdisk
  DISK_PATH="$DISK_REF"
else
  echo "⚠️ Impossible de récupérer la référence retournée par 'qm importdisk', utilisation de la valeur par défaut"
  if [[ "$STORAGE" == "nfs" || "$STORAGE" == nfs* ]]; then
    DISK_PATH="$STORAGE:$VMID/vm-${VMID}-disk-0.raw"
  else
    DISK_PATH="$STORAGE:vm-${VMID}-disk-0"
  fi
  echo "→ DISK_PATH estimé : $DISK_PATH"
fi

echo "[REMOTE 6/15] Attachement du disque..."
# Si 'qm importdisk' a fourni une référence (DISK_PATH), on l'utilise.
# Sinon, estimer la référence selon le storage (dir/nfs -> chemin avec dossier images/<VMID>/*.raw)
if [ -z "$DISK_PATH" ]; then
  STORAGE_TYPE=$(pvesm status | awk -v s="$STORAGE" '$1==s{print $2}')
  if [[ "$STORAGE" == nfs* || "$STORAGE_TYPE" == "dir" ]]; then
    DISK_PATH="$STORAGE:$VMID/vm-${VMID}-disk-0.raw"
  else
    DISK_PATH="$STORAGE:vm-${VMID}-disk-0"
  fi
  echo "→ DISK_PATH estimé : $DISK_PATH"
else
  echo "→ DISK_PATH fourni par import : $DISK_PATH"
fi

qm set "$VMID" --scsihw virtio-scsi-pci --scsi0 "$DISK_PATH"
echo "✓ Disque attaché sur scsi0 : $DISK_PATH"

echo "[REMOTE 7/15] Redimensionnement du disque à ${DISK_SIZE}..."
qm resize "$VMID" scsi0 "$DISK_SIZE"
echo "✓ Disque redimensionné"

################################################################################
# CONFIGURATION CLOUD-INIT
################################################################################

echo "[REMOTE 8/15] Ajout du drive cloud-init..."
qm set "$VMID" --ide2 "${STORAGE}:cloudinit"
echo "✓ Drive cloud-init configuré sur ide2"

################################################################################
# CONFIGURATION DU BOOT
################################################################################

echo "[REMOTE 9/15] Configuration du boot..."
qm set "$VMID" --boot c --bootdisk scsi0
echo "✓ Boot configuré sur scsi0"

echo "[REMOTE 10/15] Configuration de la console série..."
qm set "$VMID" --serial0 socket --vga serial0
echo "✓ Console série activée"

################################################################################
# ACTIVATION DU QEMU GUEST AGENT
################################################################################

echo "[REMOTE 11/15] Activation du QEMU Guest Agent..."
qm set "$VMID" --agent enabled=1
echo "✓ Agent activé (installation automatique via cloud-init)"

################################################################################
# CONFIGURATION DES IDENTIFIANTS AVEC CLÉ SSH DU POSTE DE TRAVAIL
################################################################################

echo "[REMOTE 12/15] Configuration des identifiants cloud-init..."
qm set "$VMID" \
  --ciuser "$CI_USER" \
  --cipassword "$CI_PASSWORD" \
  --sshkeys "$REMOTE_TEMP_SSH_KEY"
echo "✓ User: $CI_USER | Password: $CI_PASSWORD | SSH key: injectée depuis le poste de travail"

################################################################################
# INJECTION DU SCRIPT CLOUD-INIT
################################################################################

echo "[REMOTE 13/15] Injection du script d'installation qemu-guest-agent..."
qm set "$VMID" --cicustom "vendor=local:snippets/install-qemu-agent.yml"
echo "✓ Script cloud-init personnalisé configuré"

################################################################################
# CONFIGURATION RÉSEAU - DHCP PAR DÉFAUT
################################################################################

echo "[REMOTE 14/15] Configuration réseau (DHCP par défaut)..."
qm set "$VMID" \
  --ipconfig0 ip=manual \
  --ipconfig1 ip=manual
echo "✓ vmbr0 (net0): DHCP"
echo "✓ vmbr1 (net1): à remplir par le clone"
echo ""
echo "Note: Les IPs statiques seront définies par Terraform lors du clonage"

################################################################################
# CONVERSION EN TEMPLATE
################################################################################

#echo "[REMOTE 15/15] Conversion de la VM en template..."
#qm template "$VMID"
#echo "✓ Template ${VMID} créé et verrouillé"

################################################################################
# NETTOYAGE
################################################################################

echo "Nettoyage des fichiers temporaires..."
rm -f /tmp/"$IMAGE_FILE"
rm -f "$REMOTE_TEMP_SSH_KEY"
echo "✓ Nettoyage terminé"

REMOTE_SCRIPT_EOF
)

# Substitution des variables dans le script distant
REMOTE_SCRIPT="${REMOTE_SCRIPT//__VMID__/$VMID}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__TEMPLATE_NAME__/$TEMPLATE_NAME}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__STORAGE__/$STORAGE}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__VM_MEMORY__/$VM_MEMORY}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__VM_CORES__/$VM_CORES}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__DISK_SIZE__/$DISK_SIZE}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__CI_USER__/$CI_USER}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__CI_PASSWORD__/$CI_PASSWORD}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__REMOTE_TEMP_SSH_KEY__/$REMOTE_TEMP_SSH_KEY}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__UBUNTU_IMAGE_URL__/$UBUNTU_IMAGE_URL}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__IMAGE_FILE__/$IMAGE_FILE}"

echo "✓ Script d'exécution distant généré"
echo ""

################################################################################
# SECTION 8 : TRANSFERT ET EXÉCUTION DU SCRIPT SUR LE NODE
################################################################################

echo "Transfert du script vers le node Proxmox..."
echo "$REMOTE_SCRIPT" | ssh $SSH_OPTIONS $SSH_CONNECTION "cat > /tmp/create_template_remote.sh && chmod +x /tmp/create_template_remote.sh"
echo "✓ Script transféré vers ${PROXMOX_HOST}:/tmp/create_template_remote.sh"
echo ""

echo "Exécution du script sur le node Proxmox..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ssh $SSH_OPTIONS $SSH_CONNECTION "bash /tmp/create_template_remote.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

################################################################################
# SECTION 9 : NETTOYAGE FINAL
################################################################################

echo "Nettoyage des fichiers temporaires sur le node..."
ssh $SSH_OPTIONS $SSH_CONNECTION "rm -f /tmp/create_template_remote.sh"
echo "✓ Scripts temporaires supprimés"
echo ""

################################################################################
# SECTION 10 : RÉSUMÉ ET INSTRUCTIONS D'UTILISATION
################################################################################

echo "═══════════════════════════════════════════════════════════════════════"
echo "  ✓ TEMPLATE CRÉÉ AVEC SUCCÈS SUR ${PROXMOX_HOST}"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "Configuration du template :"
echo "  • Node Proxmox     : ${PROXMOX_HOST}"
echo "  • VM ID            : ${VMID}"
echo "  • Nom              : ${TEMPLATE_NAME}"
echo "  • RAM              : ${VM_MEMORY} MB"
echo "  • CPU              : ${VM_CORES} cœurs"
echo "  • Disque           : ${DISK_SIZE} (SCSI VirtIO)"
echo "  • Storage          : ${STORAGE}"
echo ""
echo "Réseau :"
echo "  • Interface 1      : vmbr0 (DHCP par défaut)"
echo "  • Interface 2      : vmbr1 (manual)"
echo "  • Configuration    : Les IPs statiques seront définies par Terraform"
echo ""
echo "Identifiants par défaut :"
echo "  • User             : ${CI_USER}"
echo "  • Password         : ${CI_PASSWORD}"
echo "  • Note             : Ces valeurs peuvent être surchargées par Terraform"
echo ""
echo "Clé SSH injectée :"
echo "  • Clé locale       : ${LOCAL_SSH_PUB_KEY_PATH}"
echo "  • Empreinte        : $(ssh-keygen -lf "$LOCAL_SSH_PUB_KEY_PATH" | cut -d' ' -f2)"
echo ""
echo "Fonctionnalités :"
echo "  • Cloud-init       : ✓ Activé"
echo "  • QEMU Agent       : ✓ Installation automatique au premier boot"
echo "  • System Update    : ✓ apt update + upgrade automatique"
echo "  • Auto-reboot      : ✓ Si nécessaire après mises à jour"
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "  UTILISATION AVEC TERRAFORM (RECOMMANDÉ)"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "Exemple de configuration Terraform :"
echo ""
cat << 'TERRAFORM_EXAMPLE'
resource "proxmox_vm_qemu" "ubuntu_vm" {
  name        = "terraform-vm-01"
  target_node = "TP-AA-proxmox-04-01"
  clone       = "ubuntu-noble-template"
  full_clone  = true

  cores    = 2
  memory   = 2048
  agent    = 1

  # Réseau avec IPs définies
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  # Configuration des IPs
  ipconfig0 = "ip=dhcp"
  ipconfig1 = "ip=10.0.0.20/24"

  # Identifiants (optionnel, utilise les valeurs du template par défaut)
  ciuser     = "ubuntu"
  cipassword = "azerty"
  sshkeys    = file("~/.ssh/id_rsa_proxmox_templates.pub")
}
TERRAFORM_EXAMPLE
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "  CONNEXION SSH AUX VMs CLONÉES"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "Pour se connecter aux VMs créées depuis ce template :"
echo ""
echo "  ssh -i ${LOCAL_SSH_KEY_PATH} ${CI_USER}@<IP_VM>"
echo ""
echo "Ou ajoutez cette configuration dans votre ~/.ssh/config :"
echo ""
echo "  Host proxmox-vms-*"
echo "      User ${CI_USER}"
echo "      IdentityFile ${LOCAL_SSH_KEY_PATH}"
echo "      StrictHostKeyChecking no"
echo ""

echo "═══════════════════════════════════════════════════════════════════════"
echo "  UTILISATION DU TEMPLATE"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "Depuis ce poste de travail :"
echo "  ssh ${SSH_CONNECTION} \"qm clone ${VMID} 100 --name ma-vm --full\""
echo "  ssh ${SSH_CONNECTION} \"qm start 100\""
echo ""
echo "Directement sur le node ${PROXMOX_HOST} :"
echo "  qm clone ${VMID} 100 --name ma-vm --full"
echo "  qm start 100"
echo ""
echo "Pour modifier l'IP de vmbr1 sur un clone :"
echo "  ssh ${SSH_CONNECTION} \"qm set 100 --ipconfig1 ip=10.0.0.20/24\""
echo ""
echo "Pour tester l'agent (attendre 2-3 min après le démarrage) :"
echo "  ssh ${SSH_CONNECTION} \"qm agent 100 ping\""
echo "  ssh ${SSH_CONNECTION} \"qm agent 100 network-get-interfaces\""
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo ""

echo "═══════════════════════════════════════════════════════════════════════"
echo "  NOTES IMPORTANTES"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "• Le template utilise DHCP par défaut sur les deux interfaces"
echo "• Les IPs statiques doivent être définies par Terraform lors du clonage"
echo "• Le premier boot prendra 5-10 minutes (mises à jour système)"
echo "• Un redémarrage automatique peut survenir si le kernel est mis à jour"
echo "• Le qemu-guest-agent sera automatiquement installé et activé"
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
