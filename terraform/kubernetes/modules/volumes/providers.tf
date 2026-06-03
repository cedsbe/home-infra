terraform {

  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = { # tflint-ignore: terraform_unused_required_providers # Transitive dependency used by module "persistent_volume" for restapi_object resource, not directly in this module
      source  = "hashicorp/kubernetes"
      version = ">= 2.35.1"
    }
    restapi = { # tflint-ignore: terraform_unused_required_providers # Transitive dependency used by module "proxmox_volume" for restapi_object resource, not directly in this module
      source  = "Mastercard/restapi"
      version = ">= 1.20.0"
    }
  }
}
