locals {
  # Extract the primary endpoint node's IP if not explicitly provided
  primary_endpoint_ip = one([for node_name, node_config in var.talos_nodes : node_config.ip if node_config.primary_endpoint])

  # Merge cluster configuration with the derived endpoint
  talos_cluster_enriched = merge(
    var.talos_cluster,
    {
      endpoint = coalesce(var.talos_cluster.endpoint, local.primary_endpoint_ip)
    }
  )
}

resource "talos_machine_secrets" "this" {
  talos_version = local.talos_cluster_enriched.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = local.talos_cluster_enriched.name
  client_configuration = talos_machine_secrets.this.client_configuration

  # All nodes in the cluster
  nodes = [for node_name, node_config in var.talos_nodes : node_config.ip]

  # Control plane nodes serve as endpoints
  endpoints = [for node_name, node_config in var.talos_nodes : node_config.ip if node_config.machine_type == "controlplane"]
}

# Talos machine configuration must be merged into a single YAML document.
# This data source combines multiple configuration templates (common, control-plane, worker)
# into one unified v1alpha1 machine config patch per node.
data "utils_yaml_merge" "talos_config_v1alpha1" {
  for_each = var.talos_nodes

  input = compact([ # Compact to remove empty strings

    # Always apply base configuration common to all nodes
    templatefile("${path.module}/talos_machine_config_templates/common.yaml.tftpl", {
      hostname           = each.key
      node_name          = each.value.host_node
      cluster_name       = local.talos_cluster_enriched.proxmox_cluster
      kubernetes_version = local.talos_cluster_enriched.kubernetes_version
      kubelet_extra_args = local.talos_cluster_enriched.kubelet_extra_args
    }),

    # Apply control plane specific configuration (Cilium CNI injection)
    each.value.machine_type == "controlplane" ?
    templatefile("${path.module}/talos_machine_config_templates/control-plane.yaml.tftpl", {
      hostname             = each.key
      node_name            = each.value.host_node
      cluster_name         = local.talos_cluster_enriched.proxmox_cluster
      cilium_helm_template = var.cilium.inline_manifest
    }) : "",

    # Apply worker node specific configuration
    each.value.machine_type == "worker" ?
    templatefile("${path.module}/talos_machine_config_templates/worker.yaml.tftpl", {}) : "",
  ])
}

data "talos_machine_configuration" "this" {
  for_each = var.talos_nodes

  cluster_name     = local.talos_cluster_enriched.name
  cluster_endpoint = "https://${local.talos_cluster_enriched.endpoint}:6443"
  talos_version    = local.talos_cluster_enriched.talos_version
  machine_type     = each.value.machine_type
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  # Order matters: base machine configuration must be applied first,
  # followed by additional configurations (resolver, network, hostname).
  config_patches = compact([ # Compact to remove empty strings

    # Base Talos configuration (merged from multiple templates)
    data.utils_yaml_merge.talos_config_v1alpha1[each.key].output,

    # Resolver configuration (common to all nodes)
    templatefile("${path.module}/talos_machine_config_templates/resolver-config.yaml.tftpl", {}),

    # Ethernet/Network interface configuration (per-node)
    templatefile("${path.module}/talos_machine_config_templates/link-config.yaml.tftpl", {
      mac_address    = each.value.mac_address
      interface_name = each.value.interface_name
      ip             = each.value.ip
      cidr_mask      = each.value.cidr_mask != null ? each.value.cidr_mask : 24
      gateway        = each.value.gateway != null ? each.value.gateway : local.talos_cluster_enriched.gateway
    }),

    # Hostname configuration (per-node)
    templatefile("${path.module}/talos_machine_config_templates/hostname-config.yaml.tftpl", {
      hostname = each.key
    }),
  ])

}

resource "talos_machine_configuration_apply" "this" {
  depends_on = [proxmox_virtual_environment_vm.this]
  for_each   = var.talos_nodes

  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  apply_mode                  = "auto"

  lifecycle {
    # re-run config apply if vm changes
    replace_triggered_by = [proxmox_virtual_environment_vm.this[each.key]]
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.this]

  # Use the primary endpoint node for etcd bootstrap
  node                 = one([for node_name, node_config in var.talos_nodes : node_config.ip if node_config.primary_endpoint])
  endpoint             = local.talos_cluster_enriched.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
}

#
# For now, we replace the cluster health check with a simple sleep to wait for the cluster to be ready.
#
# data "talos_cluster_health" "this" {
#   depends_on = [
#     talos_machine_configuration_apply.this,
#     talos_machine_bootstrap.this
#   ]

#   skip_kubernetes_checks = false
#   client_configuration   = data.talos_client_configuration.this.client_configuration

#   control_plane_nodes = [for node_name, node_config in var.talos_nodes : node_config.ip if node_config.machine_type == "controlplane"]
#   endpoints           = data.talos_client_configuration.this.endpoints
#   worker_nodes        = [for node_name, node_config in var.talos_nodes : node_config.ip if node_config.machine_type == "worker"]

#   timeouts = {
#     read = "15m"
#   }
# }

resource "time_sleep" "wait_for_cluster" {
  depends_on = [
    talos_machine_configuration_apply.this,
    talos_machine_bootstrap.this
  ]

  create_duration = "10m"
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this,
    #data.talos_cluster_health.this
    time_sleep.wait_for_cluster
  ]

  # Use the primary endpoint node to retrieve the kubeconfig
  node                 = one([for node_name, node_config in var.talos_nodes : node_config.ip if node_config.primary_endpoint])
  endpoint             = local.talos_cluster_enriched.endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
  timeouts = {
    read = "1m"
  }
}
