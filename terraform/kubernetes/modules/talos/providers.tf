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

    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.1"
    }

    utils = {
      source  = "netascode/utils"
      version = "2.0.2"
    }
  }
}
