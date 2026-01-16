═══════════════════════════════════════════════════════════════════════
  ✓ TEMPLATE CRÉÉ AVEC SUCCÈS SUR 172.19.15.193
═══════════════════════════════════════════════════════════════════════

Configuration du template :
  • Node Proxmox     : 172.19.15.193
  • VM ID            : 5000
  • Nom              : new-ubuntu-noble-template
  • RAM              : 16384 MB
  • CPU              : 4 cœurs
  • Disque           : 5G (SCSI VirtIO)
  • Storage          : nfsstorage

Réseau :
  • Interface 1      : vmbr0 (DHCP par défaut)
  • Interface 2      : vmbr1 (manual)
  • Configuration    : Les IPs statiques seront définies par Terraform

Identifiants par défaut :
  • User             : ubuntu
  • Password         : azerty
  • Note             : Ces valeurs peuvent être surchargées par Terraform

Clé SSH injectée :
  • Clé locale       : /home/user/.ssh/id_rsa_proxmox_templates.pub
  • Empreinte        : SHA256:L6YCDsbVT8KKmTDistCxevXY00HPhIKQLDdTxMbZkMQ

Fonctionnalités :
  • Cloud-init       : ✓ Activé
  • QEMU Agent       : ✓ Installation automatique au premier boot
  • System Update    : ✓ apt update + upgrade automatique
  • Auto-reboot      : ✓ Si nécessaire après mises à jour

═══════════════════════════════════════════════════════════════════════
  UTILISATION AVEC TERRAFORM (RECOMMANDÉ)
═══════════════════════════════════════════════════════════════════════

Exemple de configuration Terraform :

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

═══════════════════════════════════════════════════════════════════════
  CONNEXION SSH AUX VMs CLONÉES
═══════════════════════════════════════════════════════════════════════

Pour se connecter aux VMs créées depuis ce template :

  ssh -i /home/user/.ssh/id_rsa_proxmox_templates ubuntu@<IP_VM>

Ou ajoutez cette configuration dans votre ~/.ssh/config :

  Host proxmox-vms-*
      User ubuntu
      IdentityFile /home/user/.ssh/id_rsa_proxmox_templates
      StrictHostKeyChecking no

═══════════════════════════════════════════════════════════════════════
  UTILISATION DU TEMPLATE
═══════════════════════════════════════════════════════════════════════

Depuis ce poste de travail :
  ssh root@172.19.15.193 "qm clone 5000 100 --name ma-vm --full"
  ssh root@172.19.15.193 "qm start 100"

Directement sur le node 172.19.15.193 :
  qm clone 5000 100 --name ma-vm --full
  qm start 100

Pour modifier l'IP de vmbr1 sur un clone :
  ssh root@172.19.15.193 "qm set 100 --ipconfig1 ip=10.0.0.20/24"

Pour tester l'agent (attendre 2-3 min après le démarrage) :
  ssh root@172.19.15.193 "qm agent 100 ping"
  ssh root@172.19.15.193 "qm agent 100 network-get-interfaces"

═══════════════════════════════════════════════════════════════════════


═══════════════════════════════════════════════════════════════════════
  NOTES IMPORTANTES
═══════════════════════════════════════════════════════════════════════

• Le template utilise DHCP par défaut sur les deux interfaces
• Les IPs statiques doivent être définies par Terraform lors du clonage
• Le premier boot prendra 5-10 minutes (mises à jour système)
• Un redémarrage automatique peut survenir si le kernel est mis à jour
• Le qemu-guest-agent sera automatiquement installé et activé

═══════════════════════════════════════════════════════════════════════