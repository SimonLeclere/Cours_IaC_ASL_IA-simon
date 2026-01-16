#A modifier :
proxmox_api_url  = "https://172.19.15.193:8006/api2/json"

proxmox_api_token_id     = "terraform-prov@pve!terraform"
proxmox_api_token_secret = "18053e80-b42a-40ee-b417-788ae2e4dc6c"

ip_address = "10.0.0.9"

# A modifier le nom si nécessaire :
template_id  = "new-ubuntu-noble-template"
bridge       = "vmbr1"
gateway      = "10.0.0.1"

# A modifier:
proxmox_node = "pve"
cores        = 4
memory       = 16384