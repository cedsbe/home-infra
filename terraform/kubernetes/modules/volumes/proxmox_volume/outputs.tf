output "node" {
  description = "The Proxmox node where the volume is created"
  value       = var.volume.node
}

output "storage" {
  description = "The Proxmox storage where the volume is created"
  value       = var.volume.storage
}

output "filename" {
  description = "The filename of the created volume"
  value       = local.filename
}
