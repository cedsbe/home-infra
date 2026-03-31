# Task Structure Documentation

## Overview

The project uses [Task](https://taskfile.dev/) for build automation with a clean separation between the main infrastructure tasks and the Packer-specific tasks.

## Structure

### Main Taskfile (`/Taskfile.yml`)
- Contains infrastructure-related tasks (Terraform, Cilium, ArgoCD, etc.)
- Includes the Packer hub Taskfile using the `includes` feature
- All Packer tasks are prefixed with `packer:` when called from the root

### Packer Hub Taskfile (`/packer/Taskfile.yml`)
- Aggregates both Windows template builders under sub-namespaces
- Exposes `validate` and `help` tasks that cover all templates
- `ws2025` namespace → Windows Server 2025 tasks
- `win11` namespace → Windows 11 tasks

### Template Taskfiles
- `/packer/windows_server_2025/Taskfile.yml` — Windows Server 2025 specific tasks
- `/packer/windows_11/Taskfile.yml` — Windows 11 specific tasks
- Both can be called directly from their own directory without any prefix

## Usage Examples

### From Project Root
```bash
# List all available tasks
task --list

# Validate all Packer templates
task packer:validate

# Windows Server 2025 tasks
task packer:ws2025:setup
task packer:ws2025:validate
task packer:ws2025:build-iso
task packer:ws2025:build-iso TEMPLATE=DcCore
task packer:ws2025:build-clone
task packer:ws2025:help

# Windows 11 tasks
task packer:win11:setup
task packer:win11:validate
task packer:win11:build-iso
task packer:win11:build-iso TEMPLATE=Enterprise
task packer:win11:build-clone
task packer:win11:help

# Infrastructure tasks (no namespace)
task bootstrap_terraform_init
task cilium_test
```

### From Packer Directory
```bash
cd packer

# Windows Server 2025 (no packer: prefix needed)
task ws2025:build-iso
task ws2025:build-clone TEMPLATE=StdDesktop

# Windows 11
task win11:build-iso
task win11:build-clone
```

### From Template Directory
```bash
cd packer/windows_server_2025
task build-iso
task validate
task help

cd packer/windows_11
task build-iso TEMPLATE=Pro
task validate
task help
```

## Key Configuration

The main Taskfile includes the Packer hub with directory enforcement:

```yaml
includes:
  packer:
    taskfile: ./packer/Taskfile.yml
    dir: ./packer
```

The `packer/Taskfile.yml` then includes the template-specific Taskfiles:

```yaml
includes:
  ws2025:
    taskfile: ./windows_server_2025/Taskfile.yml
    dir: ./windows_server_2025
  win11:
    taskfile: ./windows_11/Taskfile.yml
    dir: ./windows_11
```

The `dir` property ensures that all commands execute in the correct directory, even when called from the project root.

## Benefits

1. **Clean Separation**: Infrastructure and Packer tasks are logically separated
2. **Template Differentiation**: `ws2025` and `win11` namespaces clearly identify which template is targeted
3. **Directory Safety**: Commands always run in the correct directory
4. **Flexibility**: Can run tasks from root, `packer/`, or the template directory
5. **Maintainability**: Each Taskfile focuses on its specific domain
6. **Secure Credentials**: Environment variables loaded automatically from `.env` files

## Environment Configuration

Each template directory has its own `.env` file. Both are loaded by the root Taskfile:

```yaml
dotenv:
  - "packer/windows_server_2025/.env"
  - "packer/windows_11/.env"
```

### Setup
```bash
cd packer/windows_server_2025
cp .env.template .env
# Edit .env with your actual credentials

cd ../windows_11
cp .env.template .env
# Edit .env with your actual credentials
```

### Security Features
- `.env` files are git-ignored automatically
- Environment variables loaded by Task automatically
- Templates provided for easy setup
- No secrets in version control

### Environment Variables
- `PKR_VAR_proxmox_api_token` - Proxmox API token
- `PKR_VAR_proxmox_username` - Proxmox username (format: user@pve!token)
- `PKR_VAR_winrm_password` - Windows Administrator password
- `PKR_VAR_clone_vm_id` - VM ID to clone from (clone builds only)
