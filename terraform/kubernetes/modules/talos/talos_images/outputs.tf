output "image_base" {
  description = <<-EOT
    Base Talos image configuration used for initial cluster node provisioning.
    Contains the schematic ID, download URL, and metadata for the customized base image.
    EOT
  value = {
    architecture = var.talos_image_base.architecture
    image_id     = "${talos_image_factory_schematic.base.id}_${local.talos_image_base_version}"
    platform     = var.talos_image_base.platform
    schematic_id = talos_image_factory_schematic.base.id
    url          = data.talos_image_factory_urls.base.urls.disk_image
    version      = local.talos_image_base_version
  }
}

output "image_update" {
  description = <<-EOT
    Update Talos image configuration for cluster node upgrades.
    Contains the schematic ID, download URL, and metadata for the update image.
    Falls back to base configuration for any unspecified parameters.
    EOT
  value = {
    architecture = local.talos_image_update_built.architecture
    image_id     = "${talos_image_factory_schematic.update.id}_${local.talos_image_update_built.version}"
    platform     = local.talos_image_update_built.platform
    schematic_id = talos_image_factory_schematic.update.id
    url          = data.talos_image_factory_urls.update.urls.disk_image
    version      = local.talos_image_update_built.version
  }
}
