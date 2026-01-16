resource "proxmox_vm_qemu" "node" {
  name        = var.name
  vmid        = var.vm_id
  target_node = var.proxmox_node
  clone       = var.template_id
  full_clone  = true

  scsihw   = "virtio-scsi-single"
  #bootdisk = "scsi0"
  boot     = "order=scsi0" # Modern way to set boot order
  os_type  = "cloud-init"

  disks {
    scsi {
      scsi0 {
        disk {
          size    = "50G"
          storage = "nfsstorage" # ou local-vm
          # This helps ensure it's treated as the main boot disk 
          #replicate = false
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  memory = var.memory
  agent  = 1

  cpu {
    type  = "host"
    cores = var.cores
  }

  # Première interface réseau - vmbr0 (réseau interne/gestion)
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Deuxième interface réseau - vmbr1 (réseau externe/internet)
  network {
    id     = 1
    model  = "virtio"
    bridge = "vmbr1"
  }

  # Cloud-init
  ipconfig0 = "ip=dhcp"
  ipconfig1 = "ip=${var.ip_address}/24,gw=${var.gateway}"
  sshkeys   = file("~/.ssh/id_rsa_proxmox_templates.pub")
  start_at_node_boot = true
}
