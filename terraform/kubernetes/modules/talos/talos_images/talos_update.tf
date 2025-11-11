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
  talos_image_update_version = contains(data.talos_image_factory_versions.update.talos_versions, var.talos_image_update.version) ? var.talos_image_update.version : null

  # Build effective configuration by merging update config with base defaults
  # Any unspecified update parameter falls back to the base configuration
  talos_image_update_built = {
    version         = local.talos_image_update_version
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
        extraKernelArgs = local.talos_image_update_built.extraKernelArgs
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.update.extensions_info[*].name
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
