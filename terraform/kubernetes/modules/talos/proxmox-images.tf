# The module exposes the images url from Talos factory.
module "talos_images" {
  source = "./talos_images"

  talos_image_base = {
    version    = var.images.version_base
    extensions = var.images.extensions_base
    platform   = var.images.platform_base
  }

  talos_image_update = {
    version    = var.images.version_update
    extensions = var.images.extensions_update
    platform   = var.images.platform_update
  }
}

locals {
  talos_image_base   = module.talos_images.image_base
  talos_image_update = module.talos_images.image_update

  # ============================================================================
  # Image Selection Loop
  # ============================================================================
  # For each node, select the appropriate Talos image based on the update flag.
  # - update=true: Uses talos_image_update (newer version for upgrades)
  # - update=false: Uses talos_image_base (initial deployment version)

  download_file_loop = { for node_name, node_config in var.talos_nodes :
    node_name => {
      architecture      = node_config.update == true ? local.talos_image_update.architecture : local.talos_image_base.architecture
      proxmox_node_name = node_config.host_node
      platform          = node_config.update == true ? local.talos_image_update.platform : local.talos_image_base.platform
      schematic_id      = node_config.update == true ? local.talos_image_update.schematic_id : local.talos_image_base.schematic_id
      talos_node_name   = node_name
      update            = node_config.update
      url               = node_config.update == true ? local.talos_image_update.url : local.talos_image_base.url
      version           = node_config.update == true ? local.talos_image_update.version : local.talos_image_base.version
    }
  }
}

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = local.download_file_loop

  node_name    = each.value.proxmox_node_name
  content_type = "iso"
  datastore_id = var.images.proxmox_datastore

  file_name               = "talos-${each.value.proxmox_node_name}-${each.value.talos_node_name}-${each.value.schematic_id}-${each.value.version}-${each.value.platform}-${each.value.architecture}.iso"
  url                     = each.value.url
  decompression_algorithm = "zst"
  overwrite               = false
}
