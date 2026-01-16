output "name" {
  value = proxmox_vm_qemu.node.name
}

output "ip" {
  value = var.ip_address
}
