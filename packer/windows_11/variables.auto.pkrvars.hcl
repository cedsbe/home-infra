bridge = "vmbr0"

cdrom_drive_unattended_files_windows = "D:"

cdrom_drive_virtio_windows = "F:"

# Optimized resources for template creation
cores                           = 2
disable_pre_sysprep_breakpoints = true
disk_size_gb                    = 64 # Windows 11 minimum requirement
disk_storage                    = "local-lvm"
efi_storage                     = "local-lvm"

image_index = {
  "Pro"          = 6
  "ProN"         = 7
  "Enterprise"   = 12
  "EnterpriseN"  = 13
  "Education"    = 4
  "EducationN"   = 5
}

iso_storage    = "local"
memory         = 4096
proxmox_node   = "hsp-proxmox0"
proxmox_url    = "https://hsp-proxmox0.ad.ghiot.be:8006/api2/json"
sockets        = 1
template       = "Pro"
windows_iso    = "local:iso/en-us_windows_11_business_editions_version_25h2_updated_march_2026_x64_dvd_caf999ab.iso"
virtio_win_iso = "local:iso/virtio-win-0.1.271.iso"
winrm_username = "Administrator"

# Debug settings - disable for production builds
disable_debug_breakpoints = true
