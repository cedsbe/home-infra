# Windows 11 Scan Client Configuration
# Uses the windows_clone_vm module to create a Windows 11 scan client VM
# Purpose: Dedicated scan client for Brother MFC-L2740DW scanner suite and Evernote
# Workflow: Scan from MFC to a folder watched by Evernote for document management

module "hsv_scan0" {
  source = "./modules/windows_clone_vm"

  # Basic VM Configuration
  vm_name     = "hsv-scan0"
  vm_id       = 601 # First in 600-range for client workstations
  clone_vm_id = 101 # Template VM ID to clone from (Windows 11)
  node_name   = var.proxmox.node_name
  datastore   = "local-lvm"

  # Resource allocation optimized for desktop client workstation
  cores     = 2 # Sufficient for Brother suite and Evernote
  sockets   = 1
  memory    = 4096 # 4GB RAM - adequate for scanner driver and document management
  disk_size = 80   # 80GB - storage for scanner drivers, documents, and Evernote sync

  # Network configuration
  network_bridge = "vmbr0" # Main bridge for domain network access
  ip_config = {
    ipv4 = {
      address = "192.168.65.55/24"
      gateway = "192.168.65.1"
    }
  }

  # DNS configuration for domain management
  nameservers  = ["192.168.65.30", "192.168.65.40"]
  searchdomain = "ad.ghiot.be"

  # Scan client user settings
  user_account = {
    username = "winadmin" # For reference; not updated by cloudbase-init.
    password = var.windows_admin_password
  }

  # Management and lifecycle
  protection    = false # Client machine, not critical infrastructure
  start_on_boot = true  # Auto-start scan client on system boot
  startup_order = 70    # Start after domain controllers and admin workstation
  startup_delay = 60    # Delay to allow domain services to be ready

  # Tagging for organization
  tags = [
    "windows",
    "windows-11",
    "scan-client",
    "desktop"
  ]

  description = "Windows 11 Scan Client - Brother MFC-L2740DW scanner suite and Evernote for scan-to-folder workflow"
}

# Output scan client information
output "hsv_scan0_info" {
  description = "Scan client connection and configuration information"
  value = {
    name         = module.hsv_scan0.vm_name
    vm_id        = module.hsv_scan0.vm_id
    node         = module.hsv_scan0.vm_node_name
    fqdn         = module.hsv_scan0.vm_fqdn
    ipv4_address = module.hsv_scan0.vm_ipv4_address
    cores        = module.hsv_scan0.vm_cpu_cores
    memory_mb    = module.hsv_scan0.vm_memory_mb
    disk_size_gb = module.hsv_scan0.vm_disk_size_gb
    tags         = module.hsv_scan0.vm_tags
  }
  sensitive = false
}

output "hsv_scan0_connection" {
  description = "Scan client connection information"
  value       = module.hsv_scan0.vm_connection_info
  sensitive   = true # Contains username
}
