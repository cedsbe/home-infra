proxmox = {
  cluster_name = "homelab"
  endpoint     = "https://hsp-proxmox0.ad.ghiot.be:8006"
  insecure     = true
  ssh_username = "root"
}

# Cilium Configuration
cilium_version = "v1.18.3" # Uncomment and modify to override default version
