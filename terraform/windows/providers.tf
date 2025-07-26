terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "0.69.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox.endpoint
  insecure  = var.proxmox.insecure
  api_token = var.proxmox_secrets.api_token

  ssh {
    username    = var.proxmox.ssh_username
    agent       = false
    private_key = file("~/.ssh/id_rsa")
  }
}
