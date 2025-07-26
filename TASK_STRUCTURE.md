# Task Structure Documentation

## Overview

The project uses [Task](https://taskfile.dev/) for build automation with a clean separation between the main infrastructure tasks and the Packer-specific tasks.

## Structure

### Main Taskfile (`/Taskfile.yml`)
- Contains infrastructure-related tasks (Terraform, Cilium, ArgoCD, etc.)
- Includes the Packer Taskfile using the `includes` feature
- All Packer tasks are prefixed with `packer:` when called from the root

### Packer Taskfile (`/packer/windows_server_2025/Taskfile.yml`)
- Contains all Packer-specific tasks for Windows Server 2025
- Can be called directly from the packer directory without prefix
- Handles environment validation, building, and cleanup

## Usage Examples

### From Project Root
```bash
# List all available tasks
task --list

# Run Packer tasks with namespace
task packer:setup
task packer:validate
task packer:build
task packer:build-dccore
task packer:build-all

# Infrastructure tasks (no namespace)
task bootstrap_terraform_init
task cilium_test
```

### From Packer Directory
```bash
cd packer/windows_server_2025

# Run tasks directly (no namespace needed)
task setup
task validate
task build
task build-dccore
task build-all
task help
```

## Key Configuration

The main Taskfile includes the Packer tasks with directory enforcement:

```yaml
includes:
  packer:
    taskfile: ./packer/windows_server_2025/Taskfile.yml
    dir: ./packer/windows_server_2025
```

The `dir` property ensures that all Packer commands execute in the correct directory, even when called from the project root.

## Benefits

1. **Clean Separation**: Infrastructure and Packer tasks are logically separated
2. **Consistent Interface**: All tasks follow the same naming conventions
3. **Directory Safety**: Commands always run in the correct directory
4. **Flexibility**: Can run tasks from either root or packer directory
5. **Maintainability**: Each Taskfile focuses on its specific domain
6. **Secure Credentials**: Environment variables loaded automatically from .env file

## Environment Configuration

The project uses a `.env` file for secure credential management:

### Setup
```bash
cd packer/windows_server_2025
cp .env.template .env
# Edit .env with your actual credentials
```

### Security Features
- `.env` file is git-ignored automatically
- Environment variables loaded by Task automatically
- Template provided for easy setup
- No secrets in version control

### Environment Variables
- `PKR_VAR_proxmox_api_token` - Proxmox API token
- `PKR_VAR_proxmox_username` - Proxmox username (format: user@pve!token)
- `PKR_VAR_winrm_password` - Windows Administrator password

## Interactive Script

For users who prefer a menu-driven interface, use:
```bash
./packer_build.sh
```

This provides a friendly menu with all the Packer build options.
