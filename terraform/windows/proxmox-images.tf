
locals {
  images = {
    windows_server_2025 = {
      checksum     = "854109e1f215a29fc3541188297a6ca97c8a8f0f8c4dd6236b78dfdf845bf75e"
      datastore_id = "local"
      file_name    = "windows_server_2025-X23-81958_26100.1742.240906-0331.iso"
      image_url    = "https://oemsoc.download.prss.microsoft.com/dbazure/X23-81958_26100.1742.240906-0331.ge_release_svc_refresh_SERVER_OEMRET_x64FRE_en-us.iso_909fa35d-ba98-407d-9fef-8df76f75e133?t=34b8db0f-439b-497c-86ce-ec7ceb898bb7&P1=102816956391&P2=601&P3=2&P4=pG1WoVpBKlyWcmfj%2bt1gYgkTsP4At28ch8mG7vIQm%2fT4elz5v2ZQ3eKAN8%2fFjb1yaa4npBaABURtnI8YmrDv8p0VJmYpLCIUQ0FHEFR4IFiPgtvzwAAI8oNdiEl%2b2uM7MN8Gaju8BvIVgHRl%2fRxq0HFgrFoEGmvHZU4jY0RFsYAaHliUinDUzdVfT0IPwyWqNUJXZTSfguyphv8XZx8OQsBy3zwBp7tNHsKl36ZO2JdZK%2fyPY7QTpAr5ccazUPEa40ALhYRBJXxlQb1F0OeO7kHhW7DKK5D4Wpt5WbpjFn8MqcZBX3%2fQI6WAwzDSKIck7jYL7bYdl2ufoMRrFZrxxw%3d%3d"
      overwrite    = false
    }
    virtio = {
      checksum     = "57b0f6dc8dc92dc2ae8621f8b1bfbd8a873de9bedc788c4c4b305ea28acc77cd"
      datastore_id = "local"
      file_name    = "virtio-win.iso"
      image_url    = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
      overwrite    = false
    }
  }
}

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = local.images

  node_name    = var.proxmox.node_name
  content_type = "iso"
  datastore_id = each.value.datastore_id

  file_name          = each.value.file_name
  url                = each.value.image_url
  overwrite          = each.value.overwrite
  upload_timeout     = 3600
  checksum           = each.value.checksum
  checksum_algorithm = "sha256"
}
