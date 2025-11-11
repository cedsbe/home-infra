variable "proxmox" {
  type = object({
    cluster_name = string
    endpoint     = string
    insecure     = bool
    ssh_username = string
  })
  description = <<-EOT
    Proxmox cluster configuration for volume operations:
    - cluster_name: Proxmox cluster identifier used in volume handles.
    - endpoint: Proxmox API endpoint URL (e.g., "https://192.168.65.1:8006").
    - insecure: Whether to skip TLS certificate verification.
    - ssh_username: SSH username for Proxmox node access.
    EOT
}

variable "volumes" {
  description = <<-EOT
    Map of volumes to create, where key is the volume name:
    - node: Proxmox node where the volume will be stored (e.g., "hsp-proxmox0").
    - size: Volume size (e.g., "100G", "512Mi"). Must be compatible with Proxmox format.
    - storage: (Optional) Proxmox storage pool ID (default: "local-lvm").
    - vmid: (Optional) Virtual machine ID for volume naming (default: 9999).
    - format: (Optional) Volume format, typically "raw" or "qcow2" (default: "raw").
    EOT
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
