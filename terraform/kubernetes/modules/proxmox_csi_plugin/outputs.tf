output "namespace" {
  description = "Kubernetes namespace where Proxmox CSI plugin is deployed"
  value       = kubernetes_namespace_v1.csi_proxmox.metadata[0].name
}

output "secret_name" {
  description = "Kubernetes secret name containing Proxmox credentials for CSI plugin"
  value       = kubernetes_secret_v1.proxmox_csi_plugin.metadata[0].name
}

output "secret_namespace" {
  description = "Kubernetes namespace containing the CSI credentials secret"
  value       = kubernetes_secret_v1.proxmox_csi_plugin.metadata[0].namespace
}

output "csi_user" {
  description = "Proxmox user created for CSI plugin authentication"
  value       = proxmox_virtual_environment_user.kubernetes_csi.user_id
}

output "csi_role" {
  description = "Proxmox role ID with minimal CSI permissions"
  value       = proxmox_virtual_environment_role.csi.role_id
}
