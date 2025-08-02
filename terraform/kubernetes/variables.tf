variable "proxmox" {
  type = object({
    cluster_name = string
    endpoint     = string
    insecure     = bool
    ssh_username = string
  })
  description = "Proxmox provider configuration. Non-sensitive data."
}

variable "proxmox_secrets" {
  type = object({
    api_token = string
  })
  sensitive   = true
  description = "Proxmox provider configuration. Sensitive data."
}

variable "cilium_version" {
  type        = string
  description = "Cilium Helm chart version"
  default     = "v1.17.4"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+", var.cilium_version))
    error_message = "The cilium_version must be a valid semantic version starting with 'v' (e.g., v1.17.4)."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for the cluster"
  default     = "v1.33.0"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+", var.kubernetes_version))
    error_message = "The kubernetes_version must be a valid semantic version starting with 'v' (e.g., v1.33.0)."
  }
}
