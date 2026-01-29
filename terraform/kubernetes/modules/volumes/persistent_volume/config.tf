resource "kubernetes_persistent_volume_v1" "pv" {

  metadata {
    name = var.volume.name
  }

  spec {
    # Storage capacity must match the Proxmox volume size for consistency
    capacity = {
      storage = var.volume.capacity
    }

    # Access mode configuration for pod attachment
    access_modes       = var.volume.access_modes
    storage_class_name = var.volume.storage_class_name
    mount_options      = var.volume.mount_options
    volume_mode        = var.volume.volume_mode

    # CSI driver configuration for Proxmox storage integration
    persistent_volume_source {
      csi {
        driver        = var.volume.driver
        fs_type       = var.volume.fs_type
        volume_handle = var.volume.volume_handle
        # Volume attributes passed to the CSI driver for storage optimization
        volume_attributes = {
          cache   = var.volume.cache
          ssd     = var.volume.ssd == true ? "true" : "false"
          storage = var.volume.storage
        }
      }
    }
  }
}
