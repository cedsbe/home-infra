# System Administration Workstation Configuration
# Uses the windows_clone_vm module to create a Windows Server 2025 admin workstation
# Purpose: Central management console with all sysadmin tools (RSAT, PowerShell, consoles)
# Note: This VM will be domain-joined to ad.ghiot.be for Active Directory management

module "hsv_admin_workstation_0" {
  source = "./modules/windows_clone_vm"

  # Basic VM Configuration
  vm_name     = "hsv-admin0"
  vm_id       = 501 # Using 500+ range for home VMs
  clone_vm_id = 105 # Template VM ID to clone from
  node_name   = var.proxmox.node_name
  datastore   = "local-lvm"

  # Resource allocation optimized for admin workstation
  cores     = 4 # More cores for running management tools and consoles
  sockets   = 1
  memory    = 8192 # 8GB RAM - needed for RSAT, PowerShell, multiple console sessions
  disk_size = 100  # 100GB - storage for tools, logs, scripts, and management data

  # Network configuration
  network_bridge = "vmbr0" # Main bridge for domain network access
  ip_config = {
    ipv4 = {
      address = "192.168.65.95/24"
      gateway = "192.168.65.1"
    }
  }

  # DNS configuration for domain management
  nameservers  = ["192.168.65.30", "192.168.65.40"]
  searchdomain = "ad.ghiot.be"

  # Admin workstation user settings
  user_account = {
    username = "winadmin" # For reference; not updated by cloudbase-init.
    password = var.windows_admin_password
  }

  # Management and lifecycle
  protection    = true # Protect admin workstation from accidental deletion
  start_on_boot = true # Admin tools should be available on system start
  startup_order = 60   # Start after domain controllers (lower numbers start first)
  startup_delay = 60   # Delay to allow domain services to be ready

  # Tagging for organization
  tags = [
    "windows",
    "server-2025",
    "admin-workstation",
    "management",
    "tools"
  ]

  description = "Windows Server 2025 Admin Workstation - Central management console with RSAT, PowerShell, and sysadmin tools"
}

# Output admin workstation information
output "hsv_admin0_info" {
  description = "Admin workstation connection and configuration information"
  value = {
    name         = module.hsv_admin_workstation_0.vm_name
    vm_id        = module.hsv_admin_workstation_0.vm_id
    node         = module.hsv_admin_workstation_0.vm_node_name
    fqdn         = module.hsv_admin_workstation_0.vm_fqdn
    ipv4_address = module.hsv_admin_workstation_0.vm_ipv4_address
    cores        = module.hsv_admin_workstation_0.vm_cpu_cores
    memory_mb    = module.hsv_admin_workstation_0.vm_memory_mb
    disk_size_gb = module.hsv_admin_workstation_0.vm_disk_size_gb
    tags         = module.hsv_admin_workstation_0.vm_tags
  }
  sensitive = false
}

output "hsv_admin0_connection" {
  description = "Admin workstation connection information"
  value       = module.hsv_admin_workstation_0.vm_connection_info
  sensitive   = true # Contains username
}
