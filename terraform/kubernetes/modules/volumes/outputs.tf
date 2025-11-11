output "volumes" {
  description = "Information about created Proxmox volumes indexed by volume name"
  value = {
    for name, volume in module.proxmox_volume : name => {
      node     = volume.node
      storage  = volume.storage
      filename = volume.filename
    }
  }
}

output "persistent_volumes" {
  description = "Created Kubernetes PersistentVolume resources indexed by volume name"
  value = {
    for name, pv in module.persistent_volume : name => {
      name          = pv.pv_name
      storage_class = pv.storage_class
    }
  }
}
