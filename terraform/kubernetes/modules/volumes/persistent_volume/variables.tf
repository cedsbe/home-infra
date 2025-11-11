variable "volume" {
  description = <<-EOT
    Kubernetes persistent volume configuration for Proxmox CSI storage:
    - name: PersistentVolume resource name in Kubernetes.
    - capacity: Volume storage capacity (e.g., "100G", "512Mi"). Must match Proxmox volume size.
    - volume_handle: Unique identifier for CSI plugin in format "cluster/node/storage/filename".
    - access_modes: (Optional) How the volume can be accessed by pods (default: ["ReadWriteOnce"]).
    - storage_class_name: (Optional) Kubernetes StorageClass name (default: "proxmox-csi").
    - fs_type: (Optional) Filesystem type for formatting the volume (default: "ext4").
    - driver: (Optional) CSI driver name for Proxmox CSI plugin (default: "csi.proxmox.sinextra.dev").
    - volume_mode: (Optional) Volume mode, "Filesystem" for mount or "Block" for raw (default: "Filesystem").
    - mount_options: (Optional) Mount options applied during pod attachment (default: ["noatime"]).
    - cache: (Optional) Cache mode for Proxmox storage (default: "writethrough").
    - ssd: (Optional) Whether volume is on SSD storage for optimization hints (default: true).
    - storage: (Optional) Proxmox storage pool ID for reference (default: "local-lvm").
    EOT
  type = object({
    name               = string
    capacity           = string
    volume_handle      = string
    access_modes       = optional(list(string), ["ReadWriteOnce"])
    storage_class_name = optional(string, "proxmox-csi")
    fs_type            = optional(string, "ext4")
    driver             = optional(string, "csi.proxmox.sinextra.dev")
    volume_mode        = optional(string, "Filesystem")
    mount_options      = optional(list(string), ["noatime"])
    cache              = optional(string, "writethrough")
    ssd                = optional(bool, true)
    storage            = optional(string, "local-lvm")
  })
}
