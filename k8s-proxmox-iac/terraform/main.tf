module "k8s_master" {
  source        = "./modules/k8s-node"
  vm_id         = 8001
  name          = "k8s-master"
  ip_address    = "10.0.0.10"

  template_id  = var.template_id
  bridge        = var.bridge
  gateway       = var.gateway
  proxmox_node  = var.proxmox_node
}

module "k8s_worker1" {
  source        = "./modules/k8s-node"
  vm_id         = 8002
  name          = "k8s-worker1"
  ip_address    = "10.0.0.11"

  template_id  = var.template_id
  bridge        = var.bridge
  gateway       = var.gateway
  proxmox_node  = var.proxmox_node
}

module "k8s_worker2" {
  source        = "./modules/k8s-node"
  vm_id         = 8003
  name          = "k8s-worker2"
  ip_address    = "10.0.0.12"

  template_id  = var.template_id
  bridge        = var.bridge
  gateway       = var.gateway
  proxmox_node  = var.proxmox_node
}

module "k8s_worker3" {
  source        = "./modules/k8s-node"
  vm_id         = 8004
  name          = "k8s-worker3"
  ip_address    = "10.0.0.13"

  template_id  = var.template_id
  bridge        = var.bridge
  gateway       = var.gateway
  proxmox_node  = var.proxmox_node
}
