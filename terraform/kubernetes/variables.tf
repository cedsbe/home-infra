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
