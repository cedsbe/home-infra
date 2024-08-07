###############################################################
#
# Update Image - Contains the update image configuration
#
###############################################################

data "talos_image_factory_versions" "update" {
  filters = {
    version = var.talos_image_update.version
  }
}

locals {
  # Validate that the requested version is available
  talos_image_update_built = {
    version         = coalesce(var.talos_image_update.version, var.talos_image_base.version)
    extensions      = coalesce(var.talos_image_update.extensions, var.talos_image_base.extensions)
    extraKernelArgs = coalesce(var.talos_image_update.extraKernelArgs, var.talos_image_base.extraKernelArgs)
    architecture    = coalesce(var.talos_image_update.architecture, var.talos_image_base.architecture)
    platform        = coalesce(var.talos_image_update.platform, var.talos_image_base.platform)
  }
}

data "talos_image_factory_extensions_versions" "update" {
  talos_version = local.talos_image_update_built.version
  filters = {
    names = local.talos_image_update_built.extensions
  }
}

resource "talos_image_factory_schematic" "update" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.update.extensions_info.*.name
        }
      }
    }
  )
}

data "talos_image_factory_urls" "update" {
  talos_version = local.talos_image_update_built.version
  schematic_id  = talos_image_factory_schematic.update.id
  architecture  = local.talos_image_update_built.architecture
  platform      = local.talos_image_update_built.platform
}

output "image_update" {
  value = {
    architecture = local.talos_image_update_built.architecture
    image_id     = "${talos_image_factory_schematic.update.id}_${local.talos_image_update_built.version}"
    platform     = var.talos_image_update.platform
    schematic_id = talos_image_factory_schematic.update.id
    url          = data.talos_image_factory_urls.update.urls.disk_image
    version      = local.talos_image_update_built.version
  }
}
