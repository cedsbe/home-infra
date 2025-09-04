locals {
  powershell_scripts_iso = [
    "./build_files/scripts/disable-services.ps1",
    "./build_files/scripts/remove-features.ps1",
    "./build_files/scripts/remove-azure-arc.ps1",
    "./build_files/scripts/install-sdelete.ps1",
    "./build_files/scripts/config-os.ps1",
  ]
}

source "proxmox-iso" "windows2025" {

  # Proxmox Host Connection
  proxmox_url              = var.proxmox_url
  insecure_skip_tls_verify = true
  username                 = var.proxmox_username
  token                    = var.proxmox_api_token
  node                     = var.proxmox_node

  # BIOS - UEFI
  bios = "ovmf"

  # Machine type
  # Q35 less resource overhead and newer chipset
  machine = "q35"

  boot = "order=scsi0;ide2;ide0;net0;ide1"

  # Windows Server ISO File
  boot_iso {
    iso_file = var.windows_iso
    unmount  = true
    type     = "ide"
    index    = 2
  }

  additional_iso_files {
    cd_files = ["./build_files/scripts/initial-setup.ps1", "./build_files"]
    cd_content = {
      "autounattend.xml" = (
        templatefile("./build_files/configs/unattended/unattended-iso.xml.pkrtpl",
          {
            password                             = var.winrm_password,
            cdrom_drive_virtio_windows           = var.cdrom_drive_virtio_windows,
            cdrom_drive_virtio_winre             = var.cdrom_drive_virtio_winre,
            cdrom_drive_unattended_files_windows = var.cdrom_drive_unattended_files_windows,
            cdrom_drive_unattended_files_winre   = var.cdrom_drive_unattended_files_winre,
            index                                = lookup(var.image_index, var.template, "DcDesktop")
          }
        )
      )
      "unattend.xml" = (
        templatefile("./build_files/configs/unattended/unattended-clone.xml.pkrtpl",
          {
            password                             = var.winrm_password,
            cdrom_drive_unattended_files_windows = var.cdrom_drive_unattended_files_windows
          }
        )
      )
    }
    cd_label         = "Unattended"
    iso_storage_pool = var.iso_storage
    unmount          = true
    type             = "ide"
    index            = 0
  }

  additional_iso_files {
    iso_file = var.virtio_win_iso
    type     = "ide"
    unmount  = true
    index    = 1
  }

  template_name        = "template-win2025-${var.template}"
  template_description = "Created on: ${timestamp()}"
  vm_name              = "win25-${var.template}"
  memory               = var.memory
  cores                = var.cores
  sockets              = var.sockets
  cpu_type             = "x86-64-v2-AES"
  os                   = "win11"
  scsi_controller      = "virtio-scsi-single"
  cloud_init           = false
  qemu_agent           = true

  # Network
  network_adapters {
    model  = "virtio"
    bridge = var.bridge
  }

  # Storage
  disks {
    storage_pool = var.disk_storage
    type         = "scsi"
    disk_size    = "${var.disk_size_gb}G"
    cache_mode   = "writeback"
    format       = "raw"
    io_thread    = true
  }

  # WinRM Configuration
  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "12h"
  winrm_port     = "5985"
  winrm_use_ssl  = false
  winrm_insecure = true

  # Boot Configuration
  boot_wait = "8s"
  boot_command = [
    "<enter>"
  ]

  tpm_config {
    tpm_storage_pool = var.efi_storage
    tpm_version      = "v2.0"
  }

  efi_config {
    efi_storage_pool  = var.efi_storage
    pre_enrolled_keys = true
    efi_type          = "4m"
  }
}

build {
  name    = "iso_build"
  sources = ["source.proxmox-iso.windows2025"]

  provisioner "windows-restart" {
    pause_before = "10m" # Wait for the Windows installation to settle
  }

  provisioner "breakpoint" {
    disable = var.disable_debug_breakpoints
    note    = "Debug breakpoint 1. Wait before starting the installation."
  }

  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    scripts           = local.powershell_scripts_iso
  }

  provisioner "breakpoint" {
    disable = var.disable_debug_breakpoints
    note    = "Debug breakpoint 2. Wait before starting the updates."
  }

  provisioner "windows-update" {
    search_criteria = "BrowseOnly=0 and IsInstalled=0"
    filters = [
      "exclude:$_.Title -like '*Preview*'",
      "include:$true",
    ]
    update_limit = 25
  }

  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'Machine restarted.'}\""
  }

  provisioner "breakpoint" {
    disable = var.disable_pre_sysprep_breakpoints
    note    = "Sysprep breakpoint. Wait before starting the sysprep generalize process."
  }

  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    scripts           = ["./build_files/scripts/generalize-iso.ps1"]
  }
}
