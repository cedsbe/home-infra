locals {
  talos_cluster_enriched = {
    endpoint        = coalesce(var.talos_cluster.endpoint, one([for k, v in var.talos_nodes : v.ip if v.primary_endpoint]))
    gateway         = var.talos_cluster.gateway
    name            = var.talos_cluster.name
    proxmox_cluster = var.talos_cluster.proxmox_cluster
    talos_version   = var.talos_cluster.talos_version
  }
}


resource "talos_machine_secrets" "this" {
  talos_version = local.talos_cluster_enriched.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = local.talos_cluster_enriched.name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for k, v in var.talos_nodes : v.ip]
  endpoints            = [for k, v in var.talos_nodes : v.ip if v.machine_type == "controlplane"]
}

data "talos_machine_configuration" "this" {
  for_each = var.talos_nodes

  cluster_name     = local.talos_cluster_enriched.name
  cluster_endpoint = "https://${local.talos_cluster_enriched.endpoint}:6443"
  talos_version    = local.talos_cluster_enriched.talos_version
  machine_type     = each.value.machine_type
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = each.value.machine_type == "controlplane" ? [
    templatefile("${path.module}/talos_machine_config/control-plane.yaml.tftpl", {
      hostname             = each.key
      node_name            = each.value.host_node
      cluster_name         = local.talos_cluster_enriched.proxmox_cluster
      cilium_helm_template = var.cilium.inline_manifest
    })
    ] : [
    templatefile("${path.module}/talos_machine_config/worker.yaml.tftpl", {
      hostname     = each.key
      node_name    = each.value.host_node
      cluster_name = local.talos_cluster_enriched.proxmox_cluster
    })
  ]
}

resource "talos_machine_configuration_apply" "this" {
  depends_on = [proxmox_virtual_environment_vm.this]
  for_each   = var.talos_nodes

  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration

  lifecycle {
    # re-run config apply if vm changes
    replace_triggered_by = [proxmox_virtual_environment_vm.this[each.key]]
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.this]

  node                 = one([for k, v in var.talos_nodes : v.ip if v.primary_endpoint])
  endpoint             = local.talos_cluster_enriched.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.this,
    talos_machine_bootstrap.this
  ]

  skip_kubernetes_checks = false
  client_configuration   = data.talos_client_configuration.this.client_configuration

  control_plane_nodes = [for k, v in var.talos_nodes : v.ip if v.machine_type == "controlplane"]
  endpoints           = data.talos_client_configuration.this.endpoints
  worker_nodes        = [for k, v in var.talos_nodes : v.ip if v.machine_type == "worker"]

  timeouts = {
    read = "15m"
  }
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this,
    data.talos_cluster_health.this
  ]

  node                 = one([for k, v in var.talos_nodes : v.ip if v.primary_endpoint]) # arbitrary decision
  endpoint             = local.talos_cluster_enriched.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
  timeouts = {
    read = "1m"
  }
}
