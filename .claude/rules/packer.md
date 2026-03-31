---
paths:
  - "packer/**/*.pkr.hcl"
  - "packer/**/*.pkrvars.hcl"
---

# Packer Template Context

## Current Templates

| Template | Path | Purpose |
|----------|------|---------|
| Windows Server 2025 | `packer/windows_server_2025/` | Proxmox VM template for Windows Server 2025 |
| Windows 11 | `packer/windows_11/` | Proxmox VM template for Windows 11 |

## Dual Build Mode

Both templates support two build modes:

- **ISO mode**: Builds from a Windows ISO (full install, ~1-3 hours)
- **Clone mode**: Clones an existing Proxmox VM template and adds cloudbase-init (~15-45 minutes)

## Task Namespace Hierarchy

```
task packer:validate               # Validate ALL templates
task packer:ws2025:validate        # Validate Windows Server 2025 only
task packer:ws2025:setup           # Check WS2025 credentials/env
task packer:ws2025:build-iso       # Build WS2025 ISO template
task packer:ws2025:build-clone     # Build WS2025 cloudbase-init clone

task packer:win11:validate         # Validate Windows 11 only
task packer:win11:setup            # Check Win11 credentials/env
task packer:win11:build-iso        # Build Win11 ISO template
task packer:win11:build-clone      # Build Win11 cloudbase-init clone
```

**Always validate before building.** The `packer build` command is in the deny list for Claude — it must be run manually by the user.

## Credential Pattern (PKR_VAR_*)

All credentials use environment variables with the `PKR_VAR_` prefix — never hardcode in `.pkr.hcl` files:

```bash
PKR_VAR_proxmox_api_token="PVEAPIToken=user@pve!token=uuid"
PKR_VAR_proxmox_username="user@pve"
PKR_VAR_winrm_password="secure_password"
PKR_VAR_ws2025_clone_vm_id=100  # VM ID of WS2025 base template (clone builds)
PKR_VAR_win11_clone_vm_id=101   # VM ID of Win11 base template (clone builds)
```

All credentials live in a single shared `packer/.env` (gitignored), loaded by the root `Taskfile.yml`. See `packer/.env.template` for the full list. The clone VM IDs use template-specific variable names to avoid conflicts in the shared file.

## Storage Pool Variables — Never Hardcode

**Known past mistake**: Hardcoding storage pool names causes failures across environments.

Always use variables:
- `var.disk_storage` — VM disk storage pool
- `var.iso_storage` — ISO storage pool
- `var.efi_storage` — EFI partition storage pool

## Numeric Validation — No Regex for VM IDs

**Known past mistake**: Complex regex for numeric ranges is fragile and hard to debug.

Use simple numeric validation instead:
```hcl
validation {
  condition     = var.vm_id >= 100 && var.vm_id <= 999999999
  error_message = "VM ID must be between 100 and 999999999."
}
```

## Build Time Warning

ISO builds take **1-3 hours**. Clone builds take **15-45 minutes**. Warn users before suggesting a full build.

## Provisioner Sequence (Windows)

The Windows templates use a specific provisioner order:
1. File uploads (drivers, scripts)
2. WinRM-based PowerShell scripts
3. Restart provisioners between major changes (feature removal, updates)
4. Sysprep for generalization

Use `restart_check_command` and proper `restart_timeout` values to handle Windows restart cycles.
