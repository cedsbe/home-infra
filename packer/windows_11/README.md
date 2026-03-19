# Windows 11 Packer Templates

This directory contains Packer configurations for building Windows 11 templates on Proxmox VE. The project supports two build methods: **ISO-based builds** for creating base templates from scratch, and **clone-based builds** for customizing existing templates with cloud-init capabilities.

## Overview

### Supported Windows 11 Editions

| Edition | Image Index | Description |
|---------|-------------|-------------|
| **Pro** | 6 | Windows 11 Pro (default) |
| **ProN** | 7 | Windows 11 Pro N |
| **Enterprise** | 12 | Windows 11 Enterprise |
| **EnterpriseN** | 13 | Windows 11 Enterprise N |
| **Education** | 4 | Windows 11 Education |
| **EducationN** | 5 | Windows 11 Education N |

> **Note**: Image indices are for the standard multi-edition Windows 11 ISO. Verify with `dism /Get-WimInfo /WimFile:<ISO>\sources\install.wim` if using a custom ISO.

### Build Methods
1. **ISO Build** (`windows_11_iso.pkr.hcl`): Creates base templates from Windows 11 ISO
2. **Clone Build** (`windows_11_clone.pkr.hcl`): Customizes existing templates with cloud-init capabilities

## Prerequisites

- **Packer** >= 1.8.0 with plugins:
  - `proxmox` plugin v1.2.1
  - `windows-update` plugin v0.16.10
- **Proxmox VE** >= 7.0
- **Task** (optional but recommended) - [Installation guide](https://taskfile.dev/)

### Required Proxmox Resources
- **Windows 11 ISO**: Upload your Windows 11 ISO to `local:iso/`
- **VirtIO drivers ISO**: `virtio-win-0.1.271.iso`
- **Storage pools**: `local` (ISOs), `local-lvm` (VM disks and EFI)
- **Network bridge**: `vmbr0`

### Windows 11 Hardware Requirements
- Minimum 4 GB RAM (default: 4096 MB)
- Minimum 64 GB disk (default: 64 GB)
- TPM 2.0 (enabled in config)
- UEFI/Secure Boot (enabled in config via OVMF with pre-enrolled keys)
- CPU: x86-64-v2-AES or newer

## Quick Setup

### 1. Environment Configuration
```bash
cp packer/.env.template packer/.env
# Edit packer/.env with your actual Proxmox credentials
```

Required environment variables (in `packer/.env`):
```bash
PKR_VAR_proxmox_api_token=your-proxmox-api-token
PKR_VAR_proxmox_username=your-username@pve!your-token-name
PKR_VAR_winrm_password=your-secure-windows-password
PKR_VAR_win11_clone_vm_id=123  # Only needed for clone builds
```

### 2. Update ISO Filename
Edit `variables.auto.pkrvars.hcl` and set the correct filename for your Windows 11 ISO:
```hcl
windows_iso = "local:iso/your-windows-11-iso-filename-here.iso"
```

### 3. Validate Setup
```bash
task env-check    # Check environment variables
task validate     # Validate Packer configuration
```

> **Note**: The `packer/.env` file is automatically ignored by git to prevent credential leaks.

## Build Instructions

### Using Task (Recommended)

#### From Project Root
```bash
task packer:win11:setup              # Check prerequisites and environment
task packer:win11:build-iso          # Build default template (Pro ISO) - ~60-120 min
task packer:win11:build-clone        # Build clone template with cloudbase-init - ~20-45 min

# Build specific editions
task packer:win11:build-iso TEMPLATE=Enterprise    # Enterprise - ~60-120 min
task packer:win11:build-iso TEMPLATE=Education     # Education - ~60-120 min

# Clone build with explicit VM ID
task packer:win11:build-clone PKR_VAR_win11_clone_vm_id=200
```

#### From Packer Directory
```bash
cd packer/windows_11
task setup                     # Check prerequisites
task build-iso                 # Build default ISO template (Pro) - ~60-120 min
task build-clone               # Build clone template - ~20-45 min

# Build specific editions
task build-iso TEMPLATE=Enterprise    # Enterprise - ~60-120 min
task build-iso TEMPLATE=Education     # Education - ~60-120 min

task help                      # Show local commands
```

### Manual Packer Commands

#### ISO Build (Base Template)
```bash
# Default build (Pro)
packer build -only="iso_build.proxmox-iso.windows11" .

# Specific edition
packer build -var 'template=Enterprise' -only="iso_build.proxmox-iso.windows11" .
packer build -var 'template=Education' -only="iso_build.proxmox-iso.windows11" .

# Debug mode
packer build -var 'disable_debug_breakpoints=false' -only="iso_build.proxmox-iso.windows11" .
```

#### Clone Build (Cloud-Init Template)
```bash
# Build from existing template
packer build -only="clone_build.proxmox-clone.windows11" .

# With specific base VM
packer build -var 'clone_vm_id=200' -only="clone_build.proxmox-clone.windows11" .
```

## Project Structure

```
packer/windows_11/
├── main.pkr.hcl                        # Packer plugin requirements
├── variables.pkr.hcl                   # Variable definitions with validation
├── variables.auto.pkrvars.hcl          # Default configuration values
├── windows_11_iso.pkr.hcl              # ISO-based template build
├── windows_11_clone.pkr.hcl            # Clone-based template build
├── .env.template                       # Environment variables template
├── .gitignore                          # Git ignore rules
├── Taskfile.yml                        # Task automation
└── build_files/
    ├── configs/
    │   ├── cloudbase-init/             # Cloud-init configuration files
    │   └── unattended/
    │       ├── unattended-iso.xml.pkrtpl    # ISO build unattended config
    │       └── unattended-clone.xml.pkrtpl  # Clone build unattended config
    └── scripts/
        ├── config-os.ps1              # OS configuration
        ├── disable-services.ps1       # Service hardening
        ├── remove-features.ps1        # Feature cleanup
        ├── remove-azure-arc.ps1       # Azure Arc removal
        ├── install-sdelete.ps1        # SDelete installation
        ├── initial-setup.ps1          # Initial Windows setup (WinRM)
        ├── install-powershell-core.ps1  # PowerShell Core setup
        ├── install-cloudbase-init.ps1   # Cloud-init setup
        ├── configure-cloudbase-init.ps1 # Cloud-init configuration
        ├── enable-openssh.ps1           # OpenSSH server setup
        ├── set-network-private.ps1      # Network profile configuration
        ├── generalize-iso.ps1           # Sysprep for ISO builds
        └── generalize-clone.ps1         # Sysprep for clone builds
```

## Configuration

### Default Settings (variables.auto.pkrvars.hcl)
```hcl
# Resource allocation
cores = 2
memory = 4096
disk_size_gb = 64

# Proxmox configuration
proxmox_node = "hsp-proxmox0"
proxmox_url = "https://hsp-proxmox0.ad.ghiot.be:8006/api2/json"
bridge = "vmbr0"

# Storage configuration
disk_storage = "local-lvm"
efi_storage = "local-lvm"
iso_storage = "local"

# Template selection
template = "Pro"  # Default: Windows 11 Pro
```

### Available Task Commands

| Command | Description | Est. Time |
|---------|-------------|-----------|
| `task setup` | Check prerequisites and environment | < 1 min |
| `task validate` | Validate Packer configuration | < 1 min |
| `task init` | Initialize Packer plugins | 1-2 min |
| `task build-iso` | Build default ISO template (Pro) | 60-120 min |
| `task build-clone` | Build clone template with cloudbase-init | 20-45 min |
| `task clean` | Clean cache and temporary files | < 1 min |
| `task inspect` | Inspect Packer configuration | < 1 min |
| `task logs` | Show Packer logs | < 1 min |
| `task help` | Show detailed help and examples | < 1 min |

## Template Features

### ISO Build Features
- **Automated Installation**: Unattended Windows 11 installation
- **VirtIO Drivers**: Pre-installed for optimal Proxmox performance
- **Security Hardening**:
  - Disabled unnecessary services (Xbox, telemetry, Bluetooth, etc.)
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
- **OpenSSH Server**: Installed and configured at first boot via LocalScripts
- **Template Customization**: Adds cloud capabilities to existing templates
- **Metadata Support**: Instance metadata and user data processing
- **Network Configuration**: Automatic network setup via cloud-init

## Template Usage

### Created Templates
After successful builds, templates will be available in Proxmox:

**ISO Build**: `template-win11-{edition}`
- Examples: `template-win11-Pro`, `template-win11-Enterprise`

**Clone Build**: `template-win11-cloudbase-{edition}`
- Example: `template-win11-cloudbase-Pro`

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

### Resource Adjustments
Edit `variables.auto.pkrvars.hcl`:
```hcl
memory = 8192       # Increase for more intensive builds
cores = 4           # More cores for faster builds
disk_size_gb = 100  # Larger disk if needed
```

## Troubleshooting

### Common Issues

#### WinRM connection fails
- **Cause**: Network configuration or firewall blocking WinRM
- **Solution**:
  - Verify bridge network configuration
  - Check that `initial-setup.ps1` enables WinRM properly
  - Ensure Windows firewall allows WinRM

#### Windows 11 installation hangs at hardware check
- **Cause**: TPM or Secure Boot not properly configured in Proxmox
- **Solution**:
  - Ensure TPM 2.0 is enabled (configured in the Packer template)
  - Ensure OVMF with pre-enrolled keys is used (configured in the Packer template)

#### Sysprep fails
- **Cause**: Services still running or pending reboots
- **Solution**:
  - Check Windows Event Logs for specific errors
  - Ensure all custom software is sysprep-compatible
  - Review script execution order

#### Wrong image index installed
- **Cause**: ISO has different image indices than expected
- **Solution**: Verify with `dism /Get-WimInfo /WimFile:<mount>\sources\install.wim`
  and update the `image_index` map in `variables.auto.pkrvars.hcl`

### Debug Mode
Enable breakpoints to pause build at specific stages:
```bash
task build-iso DEBUG=true
task build-clone DEBUG=true
```

### Logging
Enable detailed Packer logging:
```bash
export PACKER_LOG=1
packer build -only="iso_build.proxmox-iso.windows11" .
```

## Security Considerations

### Credential Management
- **Never commit** `.env` files to version control
- **Use strong passwords** for WinRM access during builds
- **Rotate API tokens** regularly in Proxmox
- **Limit permissions** for Packer service accounts

### Template Security
- Templates include basic security hardening (services disabled, features removed)
- **Additional hardening recommended** for production use

## Integration with Infrastructure

### Terraform Integration
Templates can be used with Proxmox Terraform provider:
```hcl
resource "proxmox_vm_qemu" "windows11_vm" {
  clone      = "template-win11-Pro"
  full_clone = true
  # ... additional configuration
}
```

### Cloud-Init Templates
Clone build templates support cloudbase-init for automated configuration:
```yaml
#cloud-config
users:
  - name: winadmin
    groups: administrators
    passwd: your-hashed-password
```
