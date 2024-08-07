resource "proxmox_virtual_environment_vm" "this" {

  for_each = var.talos_nodes

  node_name = each.value.host_node

  name        = each.key
  description = each.value.machine_type == "controlplane" ? "Talos Control Plane" : "Talos Worker Node"
  tags        = each.value.machine_type == "controlplane" ? ["talos", "controlplane"] : ["talos", "worker"]
  on_boot     = true
  vm_id       = each.value.vm_id

  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "seabios"

  agent {
    enabled = true
  }

  boot_order = ["scsi0"]

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  disk {
    cache        = "writethrough"
    datastore_id = each.value.datastore_id
    discard      = "on"
    file_format  = "raw"
    file_id      = proxmox_virtual_environment_download_file.this[each.key].id
    interface    = "scsi0"
    iothread     = true
    size         = 20
    ssd          = true
  }

  initialization {
    datastore_id = each.value.datastore_id
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.talos_cluster.gateway
      }
    }
  }

  memory {
    dedicated = each.value.ram_dedicated
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = each.value.mac_address
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.X.
  }
}
