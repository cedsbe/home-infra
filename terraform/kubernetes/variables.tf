variable "proxmox" {
  type = object({
    cluster_name = string
    endpoint     = string
    insecure     = bool
    ssh_username = string
  })
  description = <<-EOT
    Proxmox cluster configuration for Kubernetes infrastructure provisioning:
    - cluster_name: Proxmox cluster identifier used in volume handles (e.g., "homelab").
    - endpoint: Proxmox API endpoint URL (e.g., "https://hsp-proxmox0.ad.ghiot.be:8006").
    - insecure: Whether to skip TLS certificate verification (set to true for lab environments with self-signed certificates).
    - ssh_username: SSH username for Proxmox node access (typically "root").
    EOT
}

variable "proxmox_secrets" {
  type = object({
    api_token = string
  })
  sensitive   = true
  description = <<-EOT
    Sensitive Proxmox authentication credentials.
    - api_token: Proxmox API token in format "PVEAPIToken=user@pem!token_name=uuid-value".
    EOT
}

variable "cilium_version" {
  type        = string
  description = "Cilium CNI Helm chart version (e.g., 'v1.18.3'). Must be a valid semantic version with 'v' prefix. Cilium provides advanced networking and security policies for the cluster."

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+", var.cilium_version))
    error_message = "The cilium_version must be a valid semantic version starting with 'v' (e.g., v1.17.4)."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Target Kubernetes version for cluster deployment (e.g., 'v1.33.0'). Must be a valid semantic version with 'v' prefix. This version will be installed on all cluster nodes via Talos."

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+", var.kubernetes_version))
    error_message = "The kubernetes_version must be a valid semantic version starting with 'v' (e.g., v1.33.0)."
  }
}

variable "gateway_api_version" {
  type        = string
  description = "Kubernetes Gateway API version for advanced ingress and routing (e.g., 'v1.3.0'). Must be a valid semantic version with 'v' prefix. Enables modern ingress controller capabilities."

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+", var.gateway_api_version))
    error_message = "The gateway_api_version must be a valid semantic version starting with 'v' (e.g., v1.10.0)."
  }
}

variable "talos_version" {
  type        = string
  description = "Talos Linux version for initial cluster node provisioning (e.g., 'v1.11.3'). Must be a valid semantic version with 'v' prefix. This version is used to build the initial node images."

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+", var.talos_version))
    error_message = "The talos_version must be a valid semantic version starting with 'v' (e.g., v1.11.3)."
  }
}

variable "talos_update_version" {
  type        = string
  description = "Talos Linux version for updating cluster nodes post-deployment (e.g., 'v1.11.3'). Must be a valid semantic version with 'v' prefix. Set to same version as talos_version if no update is needed. If different, triggers node updates during apply."

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+", var.talos_update_version))
    error_message = "The talos_update_version must be a valid semantic version starting with 'v' (e.g., v1.11.3)."
  }
}

variable "oidc_issuer_url" {
  type        = string
  description = "OIDC issuer URL for Kubernetes API server authentication (e.g., 'https://auth.example.com'). This URL must be HTTPS and point to the OIDC provider's issuer endpoint."

  validation {
    condition     = can(regex("^https://", var.oidc_issuer_url))
    error_message = "The oidc_issuer_url must be a valid HTTPS URL."
  }
}

variable "oidc_client_id" {
  type        = string
  description = "OIDC client ID for Kubernetes API server authentication. This is the client identifier registered with the OIDC provider for authenticating users to the Kubernetes API."
}
