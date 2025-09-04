# Example usage of the Windows Clone VM module

# Basic Windows VM
module "basic_windows_vm" {
  source = "../"

  vm_name     = "win-test-01"
  vm_id       = 201
  clone_vm_id = 9001         # Replace with your template VM ID
  node_name   = "proxmox-01" # Replace with your Proxmox node name

  # Custom user account
  user_account = {
    username = "administrator"
    password = "MySecurePassword123!"
  }
}

# Windows VM with static IP
module "windows_vm_static_ip" {
  source = "../"

  vm_name     = "win-web-01"
  vm_id       = 202
  clone_vm_id = 9001
  node_name   = "proxmox-01"

  # Resource allocation
  cores     = 4
  memory    = 8192 # 8GB
  disk_size = 100  # 100GB

  # Static IP configuration
  ip_config = {
    ipv4 = {
      address = "192.168.1.100/24"
      gateway = "192.168.1.1"
    }
  }

  nameservers  = ["192.168.1.1", "8.8.8.8"]
  searchdomain = "local.domain"

  # Custom user account
  user_account = {
    username = "administrator"
    password = "MySecurePassword123!"
  }

  # SSH keys for management
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... admin@workstation"
  ]

  # VM management settings
  start_on_boot = true
  protection    = true
  startup_order = 100

  tags        = ["windows", "web-server", "production"]
  description = "Windows web server with static IP"
}

# High-performance Windows VM
module "windows_vm_performance" {
  source = "../"

  vm_name     = "win-app-01"
  vm_id       = 203
  clone_vm_id = 9001
  node_name   = "proxmox-02"
  datastore   = "nvme-storage" # Fast storage

  # Custom user account
  user_account = {
    username = "administrator"
    password = "MySecurePassword123!"
  }

  # High-performance configuration
  cores     = 8
  sockets   = 2
  memory    = 16384 # 16GB
  disk_size = 200   # 200GB

  # Network with VLAN
  network_bridge = "vmbr1"
  network_vlan   = 100

  # Start immediately and protect from deletion
  started       = true
  protection    = true
  start_on_boot = true

  tags        = ["windows", "application-server", "high-performance"]
  description = "High-performance Windows application server"
}

# Windows VM in DMZ
module "windows_vm_dmz" {
  source = "../"

  vm_name     = "win-dmz-01"
  vm_id       = 204
  clone_vm_id = 9001
  node_name   = "proxmox-03"

  # DMZ network configuration
  network_bridge = "vmbr2" # DMZ bridge
  network_vlan   = 200     # DMZ VLAN

  # Custom user account
  user_account = {
    username = "administrator"
    password = "MySecurePassword123!"
  }

  ip_config = {
    ipv4 = {
      address = "10.0.200.10/24"
      gateway = "10.0.200.1"
    }
  }

  nameservers = ["10.0.200.1", "1.1.1.1"]

  # Security-focused configuration
  protection = true
  started    = false # Don't auto-start for security

  tags        = ["windows", "dmz", "security"]
  description = "Windows server in DMZ network"
}

# Output examples
output "basic_vm_info" {
  description = "Basic VM connection information"
  value       = module.basic_windows_vm.vm_connection_info
}

output "static_ip_vm_info" {
  description = "Static IP VM connection information"
  value       = module.windows_vm_static_ip.vm_connection_info
}

output "all_vm_ids" {
  description = "All created VM IDs"
  value = {
    basic       = module.basic_windows_vm.vm_id
    static_ip   = module.windows_vm_static_ip.vm_id
    performance = module.windows_vm_performance.vm_id
    dmz         = module.windows_vm_dmz.vm_id
  }
}
