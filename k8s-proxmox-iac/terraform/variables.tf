variable "ip_address" {
  description = "IP statique à assigner à la VM"
  type        = string
}

variable "proxmox_api_url" {
  description = "URL API Proxmox"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token id (ex: 'user@pam!tokenid')"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nom du noeud Proxmox"
  type        = string
  default     = "mpve"
}

variable "template_id" {
  description = "nom du template cloud-init"
  default     = "test-template"
}

variable "bridge" {
  description = "Bridge réseau K8s"
  type        = string
  default     = "vmbr1"
}

variable "gateway" {
  description = "Gateway du réseau K8s"
  type        = string
  default     = "10.0.0.1"
}

variable "memory" {
  description = "RAM size for each VM in MB"
  type        = number
  default     = 4096
}

variable "cores" {
  description = "Number of CPU cores for each VM"
  type        = number
  default     = 2
}
