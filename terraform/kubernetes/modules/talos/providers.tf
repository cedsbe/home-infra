terraform {
  required_version = ">= 1.5.0"
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = ">= 0.7.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.69.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.35.1"
    }
  }
}
