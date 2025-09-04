# Windows Clone VM Terraform Module

This Terraform module creates a Windows VM by cloning from a Packer-built template in Proxmox. It's specifically optimized for Windows Server 2025 with best-practice defaults.

## Features

- ✅ Clone from existing Windows template (created with Packer)
- ✅ Optimized for Windows Server 2025
- ✅ TPM 2.0 support (required for Windows Server 2025)
- ✅ UEFI boot with SecureBoot
- ✅ VirtIO drivers for optimal performance
- ✅ Cloud-Init support for initial configuration
- ✅ Configurable CPU, memory, and disk resources
- ✅ Network configuration with VLAN support
- ✅ SSH key management
- ✅ Comprehensive validation and lifecycle management

## Requirements

- Terraform >= 1.5.0
- Proxmox provider (`bpg/proxmox`) >= 0.69.0
- A Windows template VM created with Packer
- Proxmox VE cluster with appropriate permissions

## Usage

### Basic Example

```hcl
module "windows_vm" {
  source = "./modules/windows_clone_vm"

  vm_name     = "web-server-01"
  vm_id       = 201
  clone_vm_id = 9001  # ID of your Packer-built Windows template
  node_name   = "proxmox-node-01"

  # Optional: Configure static IP
  ip_config = {
    ipv4 = {
      address = "192.168.1.100/24"
      gateway = "192.168.1.1"
    }
  }
}
```

### Advanced Example

```hcl
module "windows_vm_advanced" {
  source = "./modules/windows_clone_vm"

  vm_name     = "app-server-01"
  vm_id       = 202
  clone_vm_id = 9001
  node_name   = "proxmox-node-02"
  datastore   = "fast-ssd"

  # Resource allocation
  cores     = 4
  sockets   = 1
  memory    = 8192  # 8GB RAM
  disk_size = 120   # 120GB disk

  # Network configuration
  network_bridge = "vmbr1"
  network_vlan   = 100

  # Static IP configuration
  ip_config = {
    ipv4 = {
      address = "10.0.100.10/24"
      gateway = "10.0.100.1"
    }
  }

  nameservers   = ["10.0.100.1", "8.8.8.8"]
  searchdomain  = "internal.company.com"

  # User account configuration
  user_account = {
    username = "administrator"
    password = "YourSecurePassword123!"
  }

  # SSH keys for remote access
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAA... user@workstation"
  ]

  # VM management
  protection      = true
  start_on_boot   = true
  startup_order   = 10
  startup_delay   = 30

  # Tags for organization
  tags = ["windows", "application-server", "production"]

  description = "Production application server running Windows Server 2025"
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vm_name | The name of the virtual machine | `string` | n/a | yes |
| vm_id | The VM ID for the new VM | `number` | n/a | yes |
| clone_vm_id | The VM ID of the template to clone from | `number` | n/a | yes |
| node_name | The name of the Proxmox node where the VM will be created | `string` | n/a | yes |
| datastore | The datastore where the VM disks will be stored | `string` | `"local-lvm"` | no |
| memory | The amount of memory in MB allocated to the VM | `number` | `4096` | no |
| cores | The number of CPU cores allocated to the VM | `number` | `2` | no |
| sockets | The number of CPU sockets | `number` | `1` | no |
| disk_size | The size of the main disk in GB | `number` | `80` | no |
| network_bridge | The network bridge to connect the VM to | `string` | `"vmbr0"` | no |
| network_vlan | The VLAN tag for the network interface | `number` | `null` | no |
| ip_config | IP configuration for the VM | `object` | `null` | no |
| nameservers | List of DNS nameservers | `list(string)` | `["8.8.8.8", "8.8.4.4"]` | no |
| searchdomain | Search domain for DNS | `string` | `null` | no |
| user_account | User account configuration | `object` | See below | no |
| ssh_keys | List of SSH public keys to add to the VM | `list(string)` | `[]` | no |
| startup_order | The startup order of the VM | `number` | `null` | no |
| startup_delay | The startup delay in seconds | `number` | `null` | no |
| protection | Enable VM protection (prevents accidental deletion) | `bool` | `false` | no |
| started | Start the VM after creation | `bool` | `true` | no |
| tags | List of tags to assign to the VM | `list(string)` | `["windows", "server-2025"]` | no |
| description | Description of the VM | `string` | `"Windows Server 2025 VM created with Terraform"` | no |

### Default User Account

```hcl
user_account = {
  username = "administrator"
  password = "P@ssw0rd123!"
}
```

## Outputs

| Name | Description |
|------|-------------|
| vm_id | The ID of the created VM |
| vm_name | The name of the created VM |
| vm_fqdn | The FQDN of the VM (if searchdomain is provided) |
| vm_ipv4_address | The IPv4 address of the VM (if configured) |
| vm_ipv6_address | The IPv6 address of the VM (if configured) |
| vm_mac_addresses | The MAC addresses of the VM network interfaces |
| vm_node_name | The Proxmox node where the VM is hosted |
| vm_cpu_cores | The number of CPU cores assigned to the VM |
| vm_memory_mb | The amount of memory in MB assigned to the VM |
| vm_disk_size_gb | The size of the main disk in GB |
| vm_tags | The tags assigned to the VM |
| vm_started | Whether the VM is started |
| vm_connection_info | Connection information for the VM |

## Best Practices

### Security
- Always use strong passwords for the user account
- Consider using SSH keys instead of passwords for authentication
- Enable VM protection for production workloads
- Use appropriate VLAN segmentation

### Performance
- Use VirtIO drivers (enabled by default)
- Allocate appropriate CPU and memory resources
- Use fast storage (SSD) for better performance
- Enable QEMU Guest Agent (enabled by default)

### Management
- Use descriptive VM names and tags
- Set appropriate startup orders for dependent services
- Use protection flag for critical VMs
- Document your configuration in the description field

## Template Requirements

Your Packer template should include:
- Windows Server 2025 with latest updates
- VirtIO drivers installed
- QEMU Guest Agent installed and configured
- Cloud-Init or CloudBase-Init for initial configuration
- TPM 2.0 and UEFI boot enabled
- Appropriate Windows features and roles pre-installed

## Troubleshooting

### Common Issues

1. **Clone fails**: Ensure the source template VM exists and is in the correct state
2. **Network issues**: Verify bridge and VLAN configuration
3. **Boot problems**: Check TPM and UEFI settings match template configuration
4. **Authentication failures**: Verify user account credentials and SSH key format

### Validation

The module includes extensive validation for:
- VM ID ranges (100-999999999)
- Memory allocation (1GB-128GB)
- CPU cores (1-64)
- Disk size (40GB-2TB)
- VLAN tags (1-4094)
- Startup configuration (0-999 order, 0-3600s delay)

## Contributing

When contributing to this module:
1. Follow Terraform best practices
2. Update documentation for any new variables or outputs
3. Test with actual Proxmox environment
4. Validate with `terraform validate` and `terraform plan`

## License

This module is part of the home-infra project and follows the same license terms.
