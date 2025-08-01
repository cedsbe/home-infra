locals {
  powershell_scripts_clone = [
    "./build_files/scripts/install-cloudbase-init.ps1",
    "./build_files/scripts/configure-cloudbase-init.ps1"
  ]
}

source "proxmox-clone" "windows2025" {

  clone_vm_id = var.clone_vm_id
  full_clone  = var.full_clone

  # Proxmox Host Connection
  proxmox_url              = var.proxmox_url
  insecure_skip_tls_verify = true
  username                 = var.proxmox_username
  token                    = var.proxmox_api_token
  node                     = var.proxmox_node
  task_timeout             = "5m"

  # BIOS - UEFI
  bios = "ovmf"

  # Machine type
  # Q35 less resource overhead and newer chipset
  machine = "q35"

  boot = "order=scsi0;net0"

  template_name        = "template-win2025-cloudbase-${var.template}"
  template_description = "Created on: ${timestamp()}"
  vm_name              = "win25-cloudbase-${var.template}"
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

  additional_iso_files {
    cd_files = [
      "./build_files/scripts/initial-setup.ps1",
      "./build_files",
      "./build_files/templates/cloudbase-init/cloudbase-init-unattend.conf",
      "./build_files/templates/cloudbase-init/cloudbase-init.conf"
    ]
    cd_label         = "Unattended"
    iso_storage_pool = var.iso_storage
    unmount          = true
    type             = "ide"
    index            = 0
  }

  # WinRM Configuration
  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "12h"
  winrm_port     = "5985"
  winrm_use_ssl  = false
  winrm_insecure = true

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
  name    = "clone_build"
  sources = ["source.proxmox-clone.windows2025"]

  provisioner "windows-restart" {
    pause_before = "5m" # Wait for the Windows installation to settle
  }

  provisioner "breakpoint" {
    disable = var.disable_debug_breakpoints
    note    = "Debug breakpoint 1. Wait before starting the installation."
  }

  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    scripts           = local.powershell_scripts_clone
  }

  provisioner "breakpoint" {
    disable = var.disable_debug_breakpoints
    note    = "Debug breakpoint 2. Wait before starting the updates."
  }

  # provisioner "windows-update" {
  #   search_criteria = "BrowseOnly=0 and IsInstalled=0"
  #   filters = [
  #     "exclude:$_.Title -like '*Preview*'",
  #     "include:$true",
  #   ]
  #   update_limit = 25
  # }

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
    scripts           = ["./build_files/scripts/generalize-clone.ps1"]
  }
}
