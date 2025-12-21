# Domain Controller VM Configuration
# Uses the windows_clone_vm module to create a Windows Server 2025 domain controller

module "hsv_dc1" {
  source = "./modules/windows_clone_vm"

  # Basic VM Configuration
  vm_name     = "hsv-dc1"
  vm_id       = 301 # Using 300+ range for domain controllers
  clone_vm_id = 105 # Template VM ID to clone from
  node_name   = var.proxmox.node_name
  datastore   = "local-lvm"

  # Resource allocation optimized for domain controller
  cores     = 4 # Domain controllers benefit from multiple cores
  sockets   = 1
  memory    = 6144 # 6GB RAM - adequate for domain controller with room to grow
  disk_size = 120  # 120GB - enough for AD database, logs, and future growth

  # Network configuration
  network_bridge = "vmbr0" # Main bridge for domain services
  ip_config = {
    ipv4 = {
      address = "192.168.65.33/24"
      gateway = "192.168.65.1"
    }
  }

  # DNS configuration for domain controller
  nameservers  = ["192.168.65.30", "192.168.65.40"]
  searchdomain = "ad.ghiot.be"

  # Domain controller specific settings
  user_account = {
    username = "winadmin" # For reference; not updated by cloudbase-init.
    password = var.windows_admin_password
  }

  # Management and lifecycle
  protection    = true # Protect domain controller from accidental deletion
  start_on_boot = true # Domain controllers should start automatically
  startup_order = 10   # High priority startup (lower numbers start first)
  startup_delay = 0    # No delay for critical infrastructure

  # Tagging for organization
  tags = [
    "windows",
    "server-2025",
    "domain-controller",
    "active-directory",
    "infrastructure"
  ]

  description = "Windows Server 2025 Domain Controller - Primary DC for ad.ghiot.be domain"
}

# Output domain controller information
output "hsv_dc1_info" {
  description = "Domain controller connection and configuration information"
  value = {
    name         = module.hsv_dc1.vm_name
    vm_id        = module.hsv_dc1.vm_id
    node         = module.hsv_dc1.vm_node_name
    fqdn         = module.hsv_dc1.vm_fqdn
    ipv4_address = module.hsv_dc1.vm_ipv4_address
    cores        = module.hsv_dc1.vm_cpu_cores
    memory_mb    = module.hsv_dc1.vm_memory_mb
    disk_size_gb = module.hsv_dc1.vm_disk_size_gb
    tags         = module.hsv_dc1.vm_tags
  }
  sensitive = false
}

output "hsv_dc1_connection" {
  description = "Domain controller connection information"
  value       = module.hsv_dc1.vm_connection_info
  sensitive   = true # Contains username
}
