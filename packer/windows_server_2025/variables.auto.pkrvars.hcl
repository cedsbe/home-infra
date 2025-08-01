bridge = "vmbr0"

cdrom_drive_unattended_files_windows = "D:"
cdrom_drive_unattended_files_winre   = "D:"

cdrom_drive_virtio_windows = "F:"
cdrom_drive_virtio_winre   = "F:"

# Optimized resources for template creation
cores                           = 2
disable_pre_sysprep_breakpoints = true
disk_size_gb                    = 40 # Increased for better performance
disk_storage                    = "local-lvm"
efi_storage                     = "local-lvm"

image_index = {
  "StdCore"    = 1
  "StdDesktop" = 2
  "DcCore"     = 3
  "DcDesktop"  = 4
}

iso_storage    = "local"
memory         = 4096
proxmox_node   = "hsp-proxmox0"
proxmox_url    = "https://hsp-proxmox0.ad.ghiot.be:8006/api2/json"
sockets        = 1
template       = "DcDesktop"
windows_iso    = "local:iso/en-us_windows_server_2025_updated_july_2025_x64_dvd_a1f0681d.iso"
virtio_win_iso = "local:iso/virtio-win-0.1.271.iso"
winrm_username = "Administrator"

# Debug settings - disable for production builds
disable_debug_breakpoints = true
