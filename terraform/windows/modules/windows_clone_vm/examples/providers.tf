terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.69.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.7.0"
    }
  }
}
