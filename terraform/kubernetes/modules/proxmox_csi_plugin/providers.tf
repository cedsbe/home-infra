terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.32.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.69.0"
    }
  }
}
