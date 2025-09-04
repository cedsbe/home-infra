# Windows Server 2025 Packer Templates

This directory contains Packer configurations for building Windows Server 2025 templates on Proxmox VE. The project supports two build methods: **ISO-based builds** for creating base templates from scratch, and **clone-based builds** for customizing existing templates.

## Overview

### Supported Windows Server 2025 Editions
- **StdCore**: Standard Core (no GUI)
- **StdDesktop**: Standard with Desktop Experience
- **DcCore**: Datacenter Core (no GUI)
- **DcDesktop**: Datacenter with Desktop Experience (default)

### Build Methods
1. **ISO Build** (`windows_server_2025_iso.pkr.hcl`): Creates base templates from Windows Server 2025 ISO
2. **Clone Build** (`windows_server_2025_clone.pkr.hcl`): Customizes existing templates with cloud-init capabilities

## Prerequisites

- **Packer** >= 1.8.0 with plugins:
  - `proxmox` plugin v1.2.1
  - `windows-update` plugin v0.16.10
- **Proxmox VE** >= 7.0
- **Task** (optional but recommended) - [Installation guide](https://taskfile.dev/)

### Required Proxmox Resources
- **Windows Server 2025 ISO**: `en-us_windows_server_2025_updated_july_2025_x64_dvd_a1f0681d.iso`
- **VirtIO drivers ISO**: `virtio-win-0.1.271.iso`
- **Storage pools**: `local` (ISOs), `local-lvm` (VM disks and EFI)
- **Network bridge**: `vmbr0`

## Quick Setup

### 1. Environment Configuration
```bash
cd packer/windows_server_2025
cp .env.template .env
# Edit .env with your actual Proxmox credentials
```

Required environment variables:
```bash
PKR_VAR_proxmox_api_token=your-proxmox-api-token
PKR_VAR_proxmox_username=your-username@pve!your-token-name
PKR_VAR_winrm_password=your-secure-windows-password
PKR_VAR_clone_vm_id=123  # Only needed for clone builds
```

### 2. Validate Setup
```bash
task env-check    # Check environment variables
task validate     # Validate Packer configuration
```

> **Note**: The `.env` file is automatically ignored by git (see `.gitignore`) to prevent credential leaks.

> **⚠️ First-time setup**: If you get "permission denied" errors, ensure your Proxmox API token has sufficient permissions. See [Troubleshooting](#troubleshooting) for details.

## Build Instructions

### Using Task (Recommended)

#### From Project Root
```bash
task packer:setup              # Check prerequisites and environment
task packer:build-iso          # Build default template (DcDesktop ISO) - ~45-90 min
task packer:build-clone        # Build clone template with cloudbase-init - ~15-30 min

# Build specific editions
task packer:build-iso TEMPLATE=DcCore      # Datacenter Core - ~45-90 min
task packer:build-iso TEMPLATE=StdDesktop  # Standard Desktop - ~45-90 min
task packer:build-iso TEMPLATE=StdCore     # Standard Core - ~45-90 min

task packer:help               # Show all available commands
```

#### From Packer Directory
```bash
cd packer/windows_server_2025
task setup                     # Check prerequisites
task build-iso                 # Build default ISO template - ~45-90 min
task build-clone               # Build clone template - ~15-30 min

# Build specific editions
task build-iso TEMPLATE=DcCore      # Datacenter Core - ~45-90 min
task build-iso TEMPLATE=StdDesktop  # Standard Desktop - ~45-90 min
task build-iso TEMPLATE=StdCore     # Standard Core - ~45-90 min

task help                      # Show local commands
```

### Manual Packer Commands

#### ISO Build (Base Template)
```bash
# Default build (DcDesktop)
packer build -only="iso_build.proxmox-iso.windows2025" .

# Specific edition
packer build -var 'template=DcCore' -only="iso_build.proxmox-iso.windows2025" .
packer build -var 'template=StdDesktop' -only="iso_build.proxmox-iso.windows2025" .

# Debug mode
packer build -var 'disable_debug_breakpoints=false' -only="iso_build.proxmox-iso.windows2025" .
```

#### Clone Build (Cloud-Init Template)
```bash
# Build from existing template
packer build -only="clone_build.proxmox-clone.windows2025" .

# With specific base VM
packer build -var 'clone_vm_id=200' -only="clone_build.proxmox-clone.windows2025" .
```

## Project Structure

```
packer/windows_server_2025/
├── main.pkr.hcl                    # Packer plugin requirements
├── variables.pkr.hcl               # Variable definitions with validation
├── variables.auto.pkrvars.hcl      # Default configuration values
├── windows_server_2025_iso.pkr.hcl # ISO-based template build
├── windows_server_2025_clone.pkr.hcl # Clone-based template build
├── .env.template                   # Environment variables template
├── .gitignore                      # Git ignore rules
├── Taskfile.yml                    # Task automation
└── build_files/
    ├── configs/                    # Unattended installation configs
    │   ├── cloudbase-init/         # Cloud-init configuration files
    │   └── unattended/             # Windows unattended installation
    │       ├── unattended-iso.xml.pkrtpl   # ISO build unattended config
    │       └── unattended-clone.xml.pkrtpl # Clone build unattended config
    └── scripts/                    # PowerShell provisioning scripts
        ├── config-os.ps1          # OS optimization
        ├── disable-services.ps1   # Security hardening
        ├── remove-features.ps1    # Feature cleanup
        ├── install-cloudbase-init.ps1 # Cloud-init setup
        ├── initial-setup.ps1      # Initial Windows setup
        └── ...                     # Additional scripts
```

## Configuration

### Default Settings (variables.auto.pkrvars.hcl)
```hcl
# Resource allocation
cores = 2
memory = 4096
disk_size_gb = 40

# Proxmox configuration
proxmox_node = "hsp-proxmox0"
proxmox_url = "https://hsp-proxmox0.ad.ghiot.be:8006/api2/json"
bridge = "vmbr0"

# Storage configuration
disk_storage = "local-lvm"
efi_storage = "local-lvm"
iso_storage = "local"

# Template selection
template = "DcDesktop"  # Default: Datacenter with Desktop Experience
```

### Available Task Commands

| Command | Description | Est. Time |
|---------|-------------|-----------|
| `task setup` | Check prerequisites and environment | < 1 min |
| `task validate` | Validate Packer configuration | < 1 min |
| `task init` | Initialize Packer plugins | 1-2 min |
| `task build-iso` | Build default ISO template (DcDesktop) | 45-90 min |
| `task build-clone` | Build clone template with cloudbase-init | 15-30 min |
| `task clean` | Clean cache and temporary files | < 1 min |
| `task inspect` | Inspect Packer configuration | < 1 min |
| `task logs` | Show Packer logs | < 1 min |
| `task help` | Show detailed help and examples | < 1 min |

## Template Features

### ISO Build Features
- **Automated Installation**: Unattended Windows Server 2025 installation
- **VirtIO Drivers**: Pre-installed for optimal Proxmox performance
- **Security Hardening**:
  - Disabled unnecessary services
  - Removed optional Windows features
  - PowerShell v2 removed
  - Firewall enabled
- **System Optimization**:
  - QEMU guest agent enabled
  - Windows Updates applied during build
  - Event logs cleared
  - Temporary files cleaned
  - Disk optimization (defrag, trim)
- **Sysprep Generalization**: Ready for cloning

### Clone Build Features
- **Cloud-Init Ready**: Cloudbase-init installed and configured
- **Template Customization**: Adds cloud capabilities to existing templates
- **Metadata Support**: Instance metadata and user data processing
- **Network Configuration**: Automatic network setup via cloud-init

## Template Usage

### Created Templates
After successful builds, templates will be available in Proxmox:

**ISO Build**: `template-win2025-{template_name}`
- Examples: `template-win2025-DcDesktop`, `template-win2025-StdCore`

**Clone Build**: `template-win2025-cloudbase-{template_name}`
- Example: `template-win2025-cloudbase-DcDesktop`

### Cloning Templates
1. Right-click template in Proxmox
2. Select "Clone"
3. Choose "Full Clone" for production use
4. Configure VM resources as needed
5. Start VM - first boot will complete sysprep

## Customization

### Adding Custom Scripts
1. Create PowerShell scripts in `build_files/scripts/`
2. Add to the appropriate script list in the Packer configuration:
   - `locals.powershell_scripts_iso` (for ISO builds)
   - `locals.powershell_scripts_clone` (for clone builds)

### Modifying Installation
- **ISO Build**: Edit `build_files/configs/unattended/unattended-iso.xml.pkrtpl` for installation customization
- **Clone Build**: Edit `build_files/configs/unattended/unattended-clone.xml.pkrtpl` for clone-specific setup
- Modify boot commands in `windows_server_2025_iso.pkr.hcl`

### Resource Adjustments
Edit `variables.auto.pkrvars.hcl`:
```hcl
memory = 8192       # Increase for more intensive builds
cores = 4           # More cores for faster builds
disk_size_gb = 60   # Larger disk if needed
```

### Storage Configuration
```hcl
disk_storage = "your-vm-storage"    # VM disk storage pool
efi_storage = "your-efi-storage"    # EFI vars storage pool
iso_storage = "your-iso-storage"    # ISO file storage pool
```

## Troubleshooting

### Common Issues

#### Build hangs during Windows installation
- **Cause**: Timing issues with boot commands or resource constraints
- **Solution**:
  - Increase memory allocation temporarily
  - Check ISO compatibility and integrity
  - Verify VirtIO driver availability

#### WinRM connection fails
- **Cause**: Network configuration or firewall blocking WinRM
- **Solution**:
  - Verify bridge network configuration
  - Check that `initial-setup.ps1` enables WinRM properly
  - Ensure Windows firewall allows WinRM

#### Sysprep fails
- **Cause**: Services still running or pending reboots
- **Solution**:
  - Check Windows Event Logs for specific errors
  - Ensure all custom software is sysprep-compatible
  - Review script execution order

#### Clone build fails to find base VM
- **Cause**: Incorrect `clone_vm_id` or VM doesn't exist
- **Solution**:
  - Verify VM ID exists in Proxmox
  - Ensure VM is in template state
  - Check VM is on the correct node

### Debug Mode
Enable breakpoints to pause build at specific stages:
```bash
# ISO build with debug
task build-iso DEBUG=true

# Clone build with debug
task build-clone DEBUG=true

# Manual Packer commands with debug
packer build -var 'disable_debug_breakpoints=false' -only="iso_build.proxmox-iso.windows2025" .
packer build -var 'disable_debug_breakpoints=false' -only="clone_build.proxmox-clone.windows2025" .
```

### Logging
Enable detailed Packer logging:
```bash
export PACKER_LOG=1

# For ISO builds
packer build -only="iso_build.proxmox-iso.windows2025" .

# For clone builds
packer build -only="clone_build.proxmox-clone.windows2025" .
```

## Security Considerations

### Credential Management
- **Never commit** `.env` files to version control
- **Use strong passwords** for WinRM access during builds
- **Rotate API tokens** regularly in Proxmox
- **Limit permissions** for Packer service accounts

### Template Security
- Templates include basic security hardening
- **Additional hardening recommended** for production use:
  - Apply latest security updates
  - Configure additional Windows security policies
  - Install endpoint protection if required
  - Review and disable unnecessary services

### Network Security
- Build process uses WinRM over HTTP (encrypted)
- Templates are isolated during build process
- **Production deployment** should use separate networks

## Performance Optimization

### Build Performance
- **Use SSD storage** for faster builds (especially for `disk_storage`)
- **Allocate sufficient memory** to avoid swapping during builds
- **Use local storage** for ISO files when possible
- **Build templates serially** to avoid resource contention

### Template Performance
- **VirtIO drivers** pre-installed for optimal I/O performance
- **QEMU guest agent** enabled for better host integration
- **Resource allocation** optimized for template creation (can be adjusted after cloning)

### Parallel Builds
For building multiple templates:
```bash
# Build different editions in parallel (if resources allow)
task build-iso TEMPLATE=DcCore &
task build-iso TEMPLATE=StdDesktop &
wait
```

## Integration with Infrastructure

### Terraform Integration
Templates can be used with Proxmox Terraform provider:
```hcl
resource "proxmox_vm_qemu" "windows_vm" {
  clone      = "template-win2025-DcDesktop"
  full_clone = true
  # ... additional configuration
}
```

### Cloud-Init Templates
Clone build templates support cloud-init for automated configuration:
```yaml
# cloud-init user-data example
#cloud-config
users:
  - name: admin
    groups: administrators
    passwd: your-hashed-password
```

## Contributing

When modifying templates:
1. **Test changes** in non-production environment
2. **Validate configuration** with `task validate`
3. **Document changes** in commit messages
4. **Follow security practices** - no hardcoded secrets
5. **Update this README** if adding new features

## Support and Documentation

- **Packer Documentation**: [packer.io](https://packer.io/)
- **Proxmox Plugin**: [GitHub](https://github.com/hashicorp/packer-plugin-proxmox)
- **Windows-Update Plugin**: [GitHub](https://github.com/rgl/packer-plugin-windows-update)
- **Task Documentation**: [taskfile.dev](https://taskfile.dev/)
