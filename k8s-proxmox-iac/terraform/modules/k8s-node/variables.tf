variable "ip_address" {
  description = "IP statique à assigner à la VM"
  type        = string
}

variable "vm_id" {
  type = number
}

variable "name" {
  type = string
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 4096
}

variable "template_id" {
  type = string
}

variable "bridge" {
  type = string
}

variable "gateway" {
  type = string
}

variable "proxmox_node" {
  type = string
}
