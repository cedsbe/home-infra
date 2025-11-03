terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "0.86.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }

    restapi = {
      source  = "Mastercard/restapi"
      version = "2.0.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.1.0"
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

provider "talos" {}

provider "helm" {
  # Note: This provider is used only for template generation, not for actual chart deployment
  # The Kubernetes configuration is not needed for template generation
}

provider "restapi" {
  uri                  = var.proxmox.endpoint
  insecure             = var.proxmox.insecure
  write_returns_object = true

  headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "PVEAPIToken=${var.proxmox_secrets.api_token}"
  }
}

provider "kubernetes" {
  host                   = module.talos.kube_config.kubernetes_client_configuration.host
  client_certificate     = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
}
