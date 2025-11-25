# ============================================================================
# Cilium CNI Bootstrap - Generate Helm template for initial cluster bootstrap
# ============================================================================
# Cilium is rendered as a Helm template here because it needs to be applied
# during the Talos bootstrap process before the cluster is fully operational.
# This approach uses the Helm provider to generate the manifest that will be
# embedded in the Talos machine configuration.

data "helm_template" "cilium_helm_template_bootstrap" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = var.cilium_version
  namespace  = "kube-system"

  kube_version = var.kubernetes_version

  values = [
    file("${path.root}/../../k8s/infra/network/cilium/values_bootstrap.yaml")
  ]

  set = [
    {
      name  = "kubeProxyReplacement"
      value = "true"
    }
  ]
}

# Track Cilium version changes to trigger manifest regeneration when version is updated
resource "terraform_data" "trigger_cilium_manifest_on_version_change" {
  input = var.cilium_version
}

# This resource ensures the Cilium manifest is regenerated when the version changes,
# even though we ignore subsequent changes to the rendered manifest. This allows
# updating Cilium by changing the version variable while preventing accidental
# re-application of unchanged manifests.
resource "terraform_data" "cilium_helm_template_bootstrap" {
  input = data.helm_template.cilium_helm_template_bootstrap.manifest

  lifecycle {
    ignore_changes = [input]
    replace_triggered_by = [
      terraform_data.trigger_cilium_manifest_on_version_change.input
    ]
  }
}

# ============================================================================
# Talos Linux Cluster Provisioning
# ============================================================================
# Creates a complete Talos Linux Kubernetes cluster on Proxmox VE with:
# - Custom node configuration templates
# - Talos image factory integration for customized boot images
# - Kubernetes bootstrap with embedded Cilium CNI
# - TLS certificate management and kubeconfig generation

module "talos" {
  source = "./modules/talos"

  images = {
    version_base      = var.talos_version
    version_update    = var.talos_update_version
    proxmox_datastore = "local"
  }

  talos_cluster = {
    gateway             = "192.168.65.1"
    name                = "talos0"
    proxmox_cluster     = "homelab"
    talos_version       = var.talos_version
    kubernetes_version  = var.kubernetes_version
    gateway_api_version = var.gateway_api_version

  }

  cilium = {
    inline_manifest = terraform_data.cilium_helm_template_bootstrap.input
  }

  talos_nodes = {
    "hsv-kctrl0" = {
      host_node        = "hsp-proxmox0"
      machine_type     = "controlplane"
      ip               = "192.168.65.110"
      mac_address      = "BC:24:11:00:00:00"
      vm_id            = "10000"
      cpu              = 4
      ram_dedicated    = 4096
      update           = false
      primary_endpoint = true
    }
    "hsv-kctrl1" = {
      host_node     = "hsp-proxmox0"
      machine_type  = "controlplane"
      ip            = "192.168.65.111"
      mac_address   = "BC:24:11:00:00:01"
      vm_id         = "11000"
      cpu           = 4
      ram_dedicated = 4096
      update        = false
    }
    "hsv-kctrl2" = {
      host_node     = "hsp-proxmox0"
      machine_type  = "controlplane"
      ip            = "192.168.65.112"
      mac_address   = "BC:24:11:00:00:02"
      vm_id         = "12000"
      cpu           = 4
      ram_dedicated = 4096
      update        = false
    }
    "hsv-kwork0" = {
      host_node     = "hsp-proxmox0"
      machine_type  = "worker"
      ip            = "192.168.65.120"
      mac_address   = "BC:24:11:08:00:00"
      vm_id         = "20000"
      cpu           = 8
      ram_dedicated = 16384
      update        = false
    }
    "hsv-kwork1" = {
      host_node     = "hsp-proxmox0"
      machine_type  = "worker"
      ip            = "192.168.65.121"
      mac_address   = "BC:24:11:08:00:01"
      vm_id         = "21000"
      cpu           = 8
      ram_dedicated = 16384
      update        = false
    }
    "hsv-kwork2" = {
      host_node     = "hsp-proxmox0"
      machine_type  = "worker"
      ip            = "192.168.65.122"
      mac_address   = "BC:24:11:08:00:02"
      vm_id         = "22000"
      cpu           = 8
      ram_dedicated = 16384
      update        = false
    }
  }
}

# ============================================================================
# Proxmox CSI Plugin - Enable persistent storage integration
# ============================================================================
# Deploys and configures the Proxmox CSI plugin in the cluster to enable
# Kubernetes persistent volumes backed by Proxmox storage. Creates:
# - Service account and RBAC roles
# - Authentication token for CSI driver
# - Kubernetes secret with Proxmox credentials

module "proxmox_csi_plugin" {
  source     = "./modules/proxmox_csi_plugin"
  depends_on = [module.talos]

  proxmox = var.proxmox
}

# ============================================================================
# Persistent Volumes - Application storage provisioning
# ============================================================================
# Creates Proxmox volumes and corresponding Kubernetes PersistentVolumes for
# application workloads. Each volume is:
# - Allocated in Proxmox storage
# - Registered as a Kubernetes PersistentVolume
# - Available for pod attachment via dynamic provisioning

module "volumes" {
  depends_on = [module.proxmox_csi_plugin]
  source     = "./modules/volumes"

  proxmox = var.proxmox

  providers = {
    restapi    = restapi
    kubernetes = kubernetes
  }

  # Application storage volumes mapping to deployment names and capacities
  volumes = {
    pv-prometheus = {
      node = "hsp-proxmox0"
      size = "50G"
    }

    pv-sonarr = {
      node = "hsp-proxmox0"
      size = "4G"
    }

    pv-radarr = {
      node = "hsp-proxmox0"
      size = "4G"
    }

    pv-lidarr = {
      node = "hsp-proxmox0"
      size = "4G"
    }

    pv-prowlarr = {
      node = "hsp-proxmox0"
      size = "1G"
    }

    pv-torrent = {
      node = "hsp-proxmox0"
      size = "1G"
    }

    pv-bazarr = {
      node = "hsp-proxmox0"
      size = "4G"
    }
  }
}
