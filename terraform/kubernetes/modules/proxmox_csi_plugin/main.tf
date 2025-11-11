resource "proxmox_virtual_environment_role" "csi" {
  role_id = "CSI"
  # Grant minimal privileges required for CSI storage operations:
  # - VM.Audit: Read VM configuration
  # - VM.Config.Disk: Manage VM disk configuration (attach/detach volumes)
  # - Datastore.Allocate: Allocate storage space
  # - Datastore.AllocateSpace: Provision new storage
  # - Datastore.Audit: Read datastore information
  privileges = [
    "VM.Audit",
    "VM.Config.Disk",
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.Audit"
  ]
}

resource "proxmox_virtual_environment_user" "kubernetes_csi" {
  user_id = "kubernetes-csi@pve"
  comment = "User for Proxmox CSI Plugin"
  # Grant ACL permissions at root path with propagation to all child resources
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.csi.role_id
  }
}

resource "proxmox_virtual_environment_user_token" "kubernetes_csi_token" {
  comment               = "Token for Proxmox CSI Plugin"
  token_name            = "csi"
  user_id               = proxmox_virtual_environment_user.kubernetes_csi.user_id
  privileges_separation = false
}

# Extract token secret from format "username@pve!token_name=UID"
# The secret is the part after the last "=" character
locals {
  proxmox_token_secret = element(
    split("=", proxmox_virtual_environment_user_token.kubernetes_csi_token.value),
    length(split("=", proxmox_virtual_environment_user_token.kubernetes_csi_token.value)) - 1
  )
}

# Kubernetes namespace for Proxmox CSI plugin with privileged Pod Security Policy
resource "kubernetes_namespace" "csi_proxmox" {
  metadata {
    name = "csi-proxmox"
    # Pod Security Policy labels allowing privileged containers required by CSI plugin
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

# Kubernetes secret containing Proxmox credentials for CSI plugin authentication
resource "kubernetes_secret" "proxmox_csi_plugin" {
  metadata {
    name      = "proxmox-csi-plugin"
    namespace = kubernetes_namespace.csi_proxmox.id
  }

  data = {
    "config.yaml" = <<EOF
clusters:
- url: "${var.proxmox.endpoint}/api2/json"
  insecure: ${var.proxmox.insecure}
  token_id: "${proxmox_virtual_environment_user_token.kubernetes_csi_token.id}"
  token_secret: "${local.proxmox_token_secret}"
  region: ${var.proxmox.cluster_name}
EOF
  }
}
