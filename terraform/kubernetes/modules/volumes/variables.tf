variable "proxmox" {
  type = object({
    cluster_name = string
    endpoint     = string
    insecure     = bool
    ssh_username = string
  })
  description = "Proxmox provider configuration. Non-sensitive data."
}

variable "volumes" {
  description = "Volume configuration"
  type = map(
    object({
      node    = string
      size    = string
      storage = optional(string, "local-lvm")
      vmid    = optional(number, 9999)
      format  = optional(string, "raw")
    })
  )
}
