###############################################################
#
# Base Image - Contains the base image configuration
#
###############################################################

data "talos_image_factory_versions" "base" {
  filters = {
    version = var.talos_image_base.version
  }
}

locals {
  # Validate that the requested version is available
  talos_image_base_version = contains(data.talos_image_factory_versions.base.talos_versions, var.talos_image_base.version) ? var.talos_image_base.version : null
}

data "talos_image_factory_extensions_versions" "base" {
  talos_version = local.talos_image_base_version
  filters = {
    names = var.talos_image_base.extensions
  }
}

resource "talos_image_factory_schematic" "base" {
  schematic = yamlencode(
    {
      customization = {
        extraKernelArgs = var.talos_image_base.extraKernelArgs
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.base.extensions_info[*].name
        }
      }
    }
  )
}

data "talos_image_factory_urls" "base" {
  talos_version = local.talos_image_base_version
  schematic_id  = talos_image_factory_schematic.base.id
  architecture  = var.talos_image_base.architecture
  platform      = var.talos_image_base.platform
}
