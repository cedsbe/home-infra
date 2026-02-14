output "machine_config" {
  description = "The machine configuration for the Talos nodes"
  value       = data.talos_machine_configuration.this
}

output "client_configuration" {
  description = "The client configuration for the Talos nodes"
  value       = data.talos_client_configuration.this
  sensitive   = true
}

output "kube_config" {
  description = "The kubeconfig for the Talos nodes"
  value       = talos_cluster_kubeconfig.this
  sensitive   = true
}

output "kube_config_raw" {
  description = "The kubeconfig for the Talos nodes with or without OIDC"
  value       = data.utils_yaml_merge.kube_config_oidc.output
  sensitive   = true
}

output "oidc_enabled" {
  description = "Whether OIDC is enabled for the cluster"
  value       = local.oidc_enabled
}
