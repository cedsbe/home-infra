locals {
  filename = "vm-${var.volume.vmid}-${var.volume.name}"
}

resource "restapi_object" "proxmox_volume" {
  path         = "/api2/json/nodes/${var.volume.node}/storage/${var.volume.storage}/content"
  id_attribute = "data"

  force_new = [var.volume.size]

  data = jsonencode({
    vmid     = var.volume.vmid
    filename = local.filename
    size     = var.volume.size
    format   = var.volume.format
  })

  # Proxmox returns a different object which we ignore. This is acceptable because
  # the returned object does not contain any information that is critical for the
  # operation of this Terraform module. Instead, we rely on the input parameters
  # (e.g., size, format, and filename) to define the desired state of the volume.
  #
  # The size is also returned in bytes, not with a prefix (e.g., 1G, 512Mi), which
  # would require additional parsing and conversion logic. By ignoring server changes,
  # we avoid unnecessary complexity and ensure consistent behavior across runs.
  #
  # Setting `ignore_all_server_changes = true` ensures that Terraform does not
  # detect changes based on the server's response, which could otherwise trigger
  # unnecessary updates or recreations of the resource. This approach assumes that
  # the server's state remains consistent with the input parameters provided.
  ignore_all_server_changes = true

  # Providing a supported parameter that doesn't do anything.
  # Supplying either `null` or an empty object makes this fall back to the `data` object.
  update_data = jsonencode({
    node = var.volume.node
  })

  lifecycle {
    prevent_destroy = false
  }
}

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
