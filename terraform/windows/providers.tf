terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.6.2"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "0.94.0"
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
    private_key = fileexists("~/.ssh/id_rsa") ? file("~/.ssh/id_rsa") : "For Validation Only"
  }
}
