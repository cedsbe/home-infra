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

## Dual Build Mode

The Windows Server 2025 template supports two build modes:

- **ISO mode**: Builds from a Windows Server 2025 ISO (full install, ~1-3 hours)
- **Clone mode**: Clones an existing Proxmox VM template (faster, ~15-30 minutes)

The build mode is controlled via variables. Check `variables.pkr.hcl` for the `build_from_iso` variable.

## Credential Pattern (PKR_VAR_*)

All credentials use environment variables with the `PKR_VAR_` prefix — never hardcode in `.pkr.hcl` files:

```bash
PKR_VAR_proxmox_api_token="PVEAPIToken=user@pve!token=uuid"
PKR_VAR_proxmox_username="user@pve"
PKR_VAR_winrm_password="secure_password"
```

These are set in `packer/windows_server_2025/.env` (gitignored). See `.env.template` for the required variables.

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

## Task Workflow

```bash
task packer:validate    # Validate template syntax (always run before build)
task packer:init        # Initialize Packer plugins
task packer:build       # Full build (requires credentials, takes 1-3 hours for ISO)
task packer:setup       # Validate environment and credentials
```

**Always validate before building.** The `packer build` command is in the deny list for Claude — it must be run manually by the user.

## Build Time Warning

ISO builds take **1-3 hours**. Clone builds take **15-30 minutes**. Warn users before suggesting a full build.

## Provisioner Sequence (Windows)

The Windows template uses a specific provisioner order:
1. File uploads (drivers, scripts)
2. WinRM-based PowerShell scripts
3. Restart provisioners between major changes (feature removal, updates)
4. Sysprep for generalization

Use `restart_check_command` and proper `restart_timeout` values to handle Windows restart cycles.
