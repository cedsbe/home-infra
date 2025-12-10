terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.6.1"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "0.89.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }

    restapi = {
      source  = "Mastercard/restapi"
      version = "2.0.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
  }
}

# ============================================================================
# Proxmox Provider Configuration
# ============================================================================
# Authenticates to Proxmox API for VM creation and management using API token.
# SSH configuration enables node-level operations for volume management.

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

# ============================================================================
# Talos Provider Configuration
# ============================================================================
# Provides Talos-specific operations like machine configuration generation,
# cluster bootstrap, and node management. Uses no explicit configuration as
# endpoints and credentials are managed by the talos module.

provider "talos" {}

# ============================================================================
# Helm Provider Configuration
# ============================================================================
# Used for template rendering only (not for chart deployment).
# Generates Cilium manifests from the Helm chart without Kubernetes connection.
# The rendered manifests are then embedded in Talos machine configurations
# for bootstrap-time application.

provider "helm" {
  # Note: This provider is used only for template generation, not for actual chart deployment
  # The Kubernetes configuration is not needed for template generation
}

# ============================================================================
# REST API Provider Configuration
# ============================================================================
# Provides low-level API access to Proxmox for volume creation via REST calls.
# Uses custom headers for API token authentication instead of standard methods
# to work with Proxmox's API token format.

provider "restapi" {
  uri                  = var.proxmox.endpoint
  insecure             = var.proxmox.insecure
  write_returns_object = true

  headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "PVEAPIToken=${var.proxmox_secrets.api_token}"
  }
}

# ============================================================================
# Kubernetes Provider Configuration
# ============================================================================
# Authenticates to the Kubernetes cluster using credentials from the Talos
# bootstrap process. This provider depends on the talos module to generate
# and distribute kubeconfig across cluster nodes.

provider "kubernetes" {
  host                   = module.talos.kube_config.kubernetes_client_configuration.host
  client_certificate     = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
}
