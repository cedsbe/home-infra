variable "volume" {
  type = object({
    name    = string
    node    = string
    size    = string
    storage = optional(string, "local-lvm")
    vmid    = optional(number, 9999)
    format  = optional(string, "raw")
  })
  description = <<-EOT
    Proxmox volume configuration:
    - name: Volume identifier used in resource naming and as part of filename.
    - node: Proxmox node where volume will be created (e.g., "hsp-proxmox0").
    - size: Volume capacity (e.g., "100G", "512Mi", "10T").
    - storage: (Optional) Proxmox storage pool ID where volume is created (default: "local-lvm").
    - vmid: (Optional) VM ID for volume filename convention "vm-{vmid}-{name}" (default: 9999).
    - format: (Optional) Disk format for the volume, typically "raw" or "qcow2" (default: "raw").
    EOT
}
