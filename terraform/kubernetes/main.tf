locals {
  talos_version = "v1.11.3"

  # tflint-ignore: terraform_unused_declarations
  talos_update_version = "v1.11.3" # renovate: github-releases=siderolabs/talos
}

# Generate Cilium Helm template
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

resource "terraform_data" "trigger_cilium_manifest_on_version_change" {
  input = var.cilium_version
}

resource "terraform_data" "cilium_helm_template_bootstrap" {
  input = data.helm_template.cilium_helm_template_bootstrap.manifest

  lifecycle {
    ignore_changes = [input]
    replace_triggered_by = [
      terraform_data.trigger_cilium_manifest_on_version_change.input
    ]
  }
}


module "talos" {
  source = "./modules/talos"

  images = {
    version_base      = local.talos_version
    proxmox_datastore = "local"
  }

  talos_cluster = {
    gateway         = "192.168.65.1"
    name            = "talos0"
    proxmox_cluster = "homelab"
    talos_version   = local.talos_version
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

module "proxmox_csi_plugin" {
  source     = "./modules/proxmox_csi_plugin"
  depends_on = [module.talos]

  proxmox = var.proxmox
}

module "volumes" {
  depends_on = [module.proxmox_csi_plugin]
  source     = "./modules/volumes"

  proxmox = var.proxmox

  providers = {
    restapi    = restapi
    kubernetes = kubernetes
  }

  volumes = {
    pv-prometheus = {
      node = "hsp-proxmox0"
      size = "10G"
    }

    # pv-torrent = {
    #   node = "hsp-proxmox0"
    #   size = "1G"
    # }
  }
}
