# Windows Server 2025 Packer Template

This directory contains Packer configuration files for building Windows Server 2025 templates on Proxmox VE.

## Overview

The template supports building the following Windows Server 2025 editions:
- **StdCore**: Standard Core (no GUI)
- **StdDesktop**: Standard with Desktop Experience
- **DcCore**: Datacenter Core (no GUI)
- **DcDesktop**: Datacenter with Desktop Experience

## Quick Setup

### Automated Setup (Recommended)
```bash
cd packer/windows_server_2025
./setup-env.sh
# Follow the prompts to create .env file
# Edit .env with your credentials
task env-check
```

### Manual Setup
```bash
cd packer/windows_server_2025
cp .env.template .env
# Edit .env with your actual credentials
```

## Prerequisites

1. **Packer** >= 1.8.0
2. **Proxmox VE** >= 7.0
3. **Windows Server 2025 ISO** uploaded to Proxmox storage
4. **VirtIO drivers ISO** uploaded to Proxmox storage
5. Valid Proxmox API credentials

## Security Setup

**⚠️ IMPORTANT**: Never commit secrets to version control!

### Method 1: Environment File (Recommended)
Create a `.env` file from the template:
```bash
cd packer/windows_server_2025
cp .env.template .env
# Edit .env with your actual credentials
```

The `.env` file should contain:
```bash
PKR_VAR_proxmox_api_token=your-api-token
PKR_VAR_proxmox_username=terraform@pve!terra
PKR_VAR_winrm_password=your-secure-password
```

### Method 2: Environment Variables
Export variables manually:
```bash
export PKR_VAR_proxmox_api_token="your-api-token"
export PKR_VAR_proxmox_username="terraform@pve!terra"
export PKR_VAR_winrm_password="your-secure-password"
```

### Method 3: External Source
Load from external source:
```bash
source .env && task packer:build
```

## Configuration

### Key Files
- `windows_server_2025.pkr.hcl` - Main Packer configuration
- `variables.pkr.hcl` - Variable definitions
- `variables.auto.pkrvars.hcl` - Default variable values
- `.env` - Environment variables (create from `.env.template`)

### Resource Optimization

The template is configured with optimized resources:
- **Memory**: 4GB (sufficient for template creation)
- **CPU**: 2 cores, 1 socket
- **Disk**: 40GB (allows for OS + updates)
- **Storage**: VirtIO SCSI with writeback cache

## Build Instructions

### Quick Start with Task (Recommended)

This project includes a Taskfile for streamlined building. If you have [Task](https://taskfile.dev/) installed:

**From the project root:**
```bash
# Check prerequisites and environment
task packer:setup

# Build default template (DcDesktop)
task packer:build

# Build specific templates
task packer:build-dccore
task packer:build-stddesktop
task packer:build-all

# Debug build with breakpoints
task packer:debug

# Get help
task packer:help
```

**From the packer directory:**
```bash
cd packer/windows_server_2025

# Check prerequisites and environment
task setup

# Build default template (DcDesktop)
task build

# Build specific templates
task build-dccore
task build-stddesktop
task build-all

# Debug build with breakpoints
task debug

# Get help
task help
```

#### Available Task Commands

**From project root (using `task packer:COMMAND`):**

| Command | Description |
|---------|-------------|
| `task packer:setup` | Check prerequisites and environment variables |
| `task packer:validate` | Validate Packer configuration |
| `task packer:build` | Build default template (DcDesktop) |
| `task packer:build-dcdesktop` | Build Datacenter Desktop template |
| `task packer:build-dccore` | Build Datacenter Core template |
| `task packer:build-stddesktop` | Build Standard Desktop template |
| `task packer:build-stdcore` | Build Standard Core template |
| `task packer:build-all` | Build all templates (takes several hours) |
| `task packer:debug` | Build with debug breakpoints enabled |
| `task packer:clean` | Clean up cache and temporary files |
| `task packer:help` | Show detailed help and examples |

**From packer directory (using `task COMMAND`):**

All the same commands but without the `packer:` prefix when run from `/packer/windows_server_2025/` directory.

### Manual Packer Commands

### 1. Validate Configuration
```bash
packer validate .
```

### 2. Build Template
```bash
# Build with environment variables
packer build .

# Build specific template
packer build -var 'template=DcCore' .

# Build with custom ISO
packer build -var 'windows_iso=local:iso/your-windows-iso.iso' .
```

### 3. Debug Build (if needed)
```bash
# Enable debug breakpoints
packer build -var 'disable_debug_breakpoints=false' .
```

## Template Features

### Security Hardening
- Disabled unnecessary services
- Removed optional Windows features
- Firewall enabled by default
- PowerShell v2 removed

### Optimizations
- VirtIO drivers installed
- QEMU guest agent enabled
- Windows Updates applied
- Disk optimization
- Event logs cleared
- Temporary files cleaned

### Post-Build
- Sysprep generalization
- Automatic shutdown
- Template ready for cloning

## Customization

### Adding Custom Scripts
Add PowerShell scripts to the `build_files/scripts/` directory and include them in the `locals.powershell_scripts` list.

### Modifying Unattended Installation
Edit `build_files/templates/unattended/unattended-iso.xml.pkrtpl` to customize the Windows installation process.

### Changing Resource Allocation
Modify values in `variables.auto.pkrvars.hcl`:
```hcl
memory = 8192  # Increase for more intensive builds
cores = 4      # More cores for faster builds
disk_size_gb = 60  # Larger disk if needed
```

## Troubleshooting

### Common Issues

1. **Build hangs during Windows installation**
   - Check boot command timing
   - Verify ISO compatibility
   - Ensure sufficient resources

2. **WinRM connection fails**
   - Verify network configuration
   - Check firewall settings
   - Confirm WinRM setup in initial-setup.ps1

3. **Sysprep fails**
   - Check for pending reboots
   - Verify all services are stopped
   - Review Windows Event Logs

### Debug Mode
Enable breakpoints to pause build at specific stages:
```bash
packer build -var 'disable_debug_breakpoints=false' .
```

## Best Practices

1. **Always test builds** in a non-production environment
2. **Keep ISOs updated** with latest Windows versions
3. **Regularly update VirtIO drivers**
4. **Monitor build logs** for warnings or errors
5. **Use version control** for configuration changes
6. **Secure credentials** properly

## Performance Tips

- Use SSD storage for faster builds
- Allocate sufficient memory to avoid swapping
- Consider parallel builds for multiple templates
- Use local storage for ISOs when possible

## Template Usage

After successful build, the template will be available in Proxmox as:
`template-win2025-{template_name}`

Clone the template to create new VMs with pre-configured Windows Server 2025.
