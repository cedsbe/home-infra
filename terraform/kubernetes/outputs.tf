resource "local_file" "machine_configs" {
  for_each = module.talos.machine_config

  content         = each.value.machine_configuration
  filename        = "output/talos_machine_config-${each.key}.yaml"
  file_permission = "0600"
}

resource "local_file" "talos_config" {
  content         = module.talos.client_configuration.talos_config
  filename        = "output/talos-config.yaml"
  file_permission = "0600"
}

resource "local_file" "kube_config" {
  content         = module.talos.kube_config.kubeconfig_raw
  filename        = "output/kube-config.yaml"
  file_permission = "0600"
}

# ============================================================================
# Cluster Credentials (Sensitive)
# ============================================================================

output "kube_config" {
  description = "Kubeconfig for accessing the Kubernetes cluster API"
  value       = module.talos.kube_config.kubeconfig_raw
  sensitive   = true
}

output "talos_config" {
  description = "Talos client configuration for node management"
  value       = module.talos.client_configuration.talos_config
  sensitive   = true
}

# ============================================================================
# Cluster Information
# ============================================================================

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint URL"
  value       = module.talos.kube_config.kubernetes_client_configuration.host
  sensitive   = true
}

# ============================================================================
# Component Versions
# ============================================================================

output "cilium_version" {
  description = "Cilium CNI version deployed to the cluster"
  value       = var.cilium_version
}

output "kubernetes_version" {
  description = "Kubernetes version running on cluster nodes"
  value       = var.kubernetes_version
}

output "talos_version" {
  description = "Talos Linux version running on cluster nodes"
  value       = var.talos_version
}

output "gateway_api_version" {
  description = "Kubernetes Gateway API version enabled on the cluster"
  value       = var.gateway_api_version
}

# ============================================================================
# Storage
# ============================================================================

output "persistent_volumes" {
  description = "Persistent volumes created for application workloads"
  value       = module.volumes.volumes
}
