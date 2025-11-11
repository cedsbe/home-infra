output "pv_name" {
  description = "Name of the created Kubernetes PersistentVolume"
  value       = kubernetes_persistent_volume.pv.metadata[0].name
}

output "storage_class" {
  description = "Storage class name used by this PersistentVolume"
  value       = var.volume.storage_class_name
}

output "capacity" {
  description = "Storage capacity of the PersistentVolume"
  value       = var.volume.capacity
}
