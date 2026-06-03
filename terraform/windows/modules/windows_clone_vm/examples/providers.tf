terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = { # tflint-ignore: terraform_unused_required_providers # Transitive dependency used by module "windows_clone_vm" for proxmox_virtual_environment_user resource, not directly in this module
      source  = "bpg/proxmox"
      version = ">=0.69.0"
    }
    time = { # tflint-ignore: terraform_unused_required_providers # Transitive dependency used by module "windows_clone_vm" for time_sleep resource, not directly in this module
      source  = "hashicorp/time"
      version = ">=0.7.0"
    }
  }
}
