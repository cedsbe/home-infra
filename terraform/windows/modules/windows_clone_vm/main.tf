locals {
  # Generate startup configuration if either order or delay is specified
  startup_config = var.startup_order != null || var.startup_delay != null ? {
    order      = var.startup_order
    up_delay   = var.startup_delay
    down_delay = null
  } : null
}

# Create the Windows VM by cloning from template
resource "proxmox_virtual_environment_vm" "windows_vm" {
  name        = var.vm_name
  description = var.description
  tags        = var.tags
  node_name   = var.node_name
  vm_id       = var.vm_id

  # Clone configuration
  clone {
    vm_id        = var.clone_vm_id
    datastore_id = var.datastore
  }

  # CPU Configuration
  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = "host"
  }

  # Memory Configuration
  memory {
    dedicated = var.memory
    floating  = var.memory
  }

  # Machine Configuration
  machine       = var.machine_type
  scsi_hardware = var.scsi_controller
  bios          = var.bios

  # Operating System
  operating_system {
    type = "win11" # Use win11 type for Windows Server 2025
  }

  # TPM Configuration (required for Windows Server 2025)
  dynamic "tpm_state" {
    for_each = var.tpm_enabled ? [1] : []
    content {
      datastore_id = var.efi_storage_pool
      version      = var.tpm_version
    }
  }

  # EFI Configuration (required for UEFI boot)
  dynamic "efi_disk" {
    for_each = var.bios == "ovmf" ? [1] : []
    content {
      datastore_id      = var.efi_storage_pool
      file_format       = "raw"
      type              = "4m"
      pre_enrolled_keys = true
    }
  }

  # Disk Configuration
  disk {
    datastore_id = var.datastore
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = var.disk_size
    file_format  = "raw"
    cache        = "writethrough"
  }

  # Network Configuration
  network_device {
    bridge  = var.network_bridge
    model   = "virtio"
    vlan_id = var.network_vlan
  }

  # Cloud-Init Configuration
  dynamic "initialization" {
    for_each = var.ip_config != null ? [1] : []
    content {
      datastore_id = var.datastore

      dynamic "ip_config" {
        for_each = var.ip_config.ipv4 != null ? [var.ip_config.ipv4] : []
        content {
          ipv4 {
            address = ip_config.value.address
            gateway = ip_config.value.gateway
          }
        }
      }

      dynamic "ip_config" {
        for_each = var.ip_config.ipv6 != null ? [var.ip_config.ipv6] : []
        content {
          ipv6 {
            address = ip_config.value.address
            gateway = ip_config.value.gateway
          }
        }
      }

      dns {
        servers = var.nameservers
        domain  = var.searchdomain
      }

      user_account {
        username = var.user_account.username
        password = var.user_account.password
        keys     = var.ssh_keys
      }
    }
  }

  # QEMU Guest Agent
  agent {
    enabled = true
    timeout = "15m"
    trim    = true
    type    = "virtio"
  }

  # VM Lifecycle Configuration
  started    = var.started
  protection = var.protection
  on_boot    = var.start_on_boot
  migrate    = true
  reboot     = false

  # Startup configuration
  dynamic "startup" {
    for_each = local.startup_config != null ? [local.startup_config] : []
    content {
      order      = startup.value.order
      up_delay   = startup.value.up_delay
      down_delay = startup.value.down_delay
    }
  }

  # Serial console for debugging (optional)
  serial_device {
    device = "socket"
  }

  # VGA Configuration
  vga {
    memory = 16
    type   = "std"
  }

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore changes to the clone source after initial creation
      clone[0].vm_id,
    ]
  }
}

# Wait for VM to be ready (optional resource for dependency management)
resource "time_sleep" "wait_for_vm" {
  depends_on = [proxmox_virtual_environment_vm.windows_vm]

  create_duration = var.started ? "60s" : "10s"
}
