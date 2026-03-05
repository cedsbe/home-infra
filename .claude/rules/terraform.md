---
paths:
  - "terraform/**/*.tf"
  - "terraform/**/*.tfvars"
  - "terraform/**/*.hcl"
---

# Terraform Workspace Context

## Workspace Inventory

| Workspace | Path | Purpose |
|-----------|------|---------|
| `kubernetes` | `terraform/kubernetes/` | Talos Linux cluster on Proxmox — VMs, networking, Talos config |
| `azure-global` | `terraform/azure/global/` | Azure backend storage account + Key Vault (shared global resources) |
| `azure-landing` | `terraform/azure/landing-static-web-app/` | Azure static web app hosting |

## Task-Driven Workflow

Always prefer `task` over raw `terraform` commands:

```bash
task kubernetes:plan    # terraform plan for k8s workspace
task kubernetes:apply   # terraform apply (requires human confirmation)
task azure-global:plan
task azure-global:apply
```

Run `task --list` in a workspace directory to see available tasks.

## Key Rules

- **`terraform_data` over `null_resource`**: Use `terraform_data` for provisioners and state management — it's the modern Terraform pattern.
- **`for_each` over `count`**: Prefer `for_each` for conditional and multiple resources — more resilient to index changes.
- **Pin provider versions**: Use exact versions or `~>` constraint (e.g., `version = "~> 4.0"`).
- **Required version**: `>= 1.9.0` — all workspaces should enforce this minimum.

## Notable Provider

The `netascode/utils` provider is pinned to `1.1.0-beta4` intentionally — this is a pre-release version used deliberately, not an accident.

## Git-Crypt Encrypted Files

These files exist but are encrypted and will not be readable without the git-crypt key:

- `*.secrets.auto.tfvars` — sensitive Terraform variable values
- `backend.config` — backend connection credentials
- `terraform/**/.env` — environment credentials

If a file appears as binary gibberish, it is git-crypt locked. Do NOT modify encrypted files. The user must run `git-crypt unlock` first.

## Backend Configuration

Each workspace uses Azure Blob Storage as the Terraform backend. The `backend.config` file (gitignored/encrypted) contains the storage account credentials. On first setup, `task <workspace>:init` handles backend initialization.

## Common Patterns

```hcl
# Correct: terraform_data for provisioners
resource "terraform_data" "validate" {
  input = local.validation_error
  provisioner "local-exec" {
    command     = self.input != "" ? "echo '${self.input}' && exit 1" : "echo 'Valid'"
    interpreter = ["/bin/sh", "-c"]
  }
}

# Correct: for_each for conditional resources
resource "azurerm_resource" "example" {
  for_each = var.create_resource ? { "main" = var.config } : {}
}
```
