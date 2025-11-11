# Copilot Instructions for home-infra

## Project Overview

This is a home infrastructure repository that automates the deployment of a Kubernetes cluster using Talos Linux on Proxmox VE. The project uses Infrastructure as Code principles with Terraform, GitOps with ArgoCD, and task automation with Task.

## Architecture

- **Virtualization Platform**: Proxmox VE
- **Kubernetes Distribution**: Talos Linux
- **Infrastructure as Code**: Terraform with modular structure
- **GitOps**: ArgoCD for application deployment
- **Container Networking**: Cilium CNI
- **Task Automation**: Task (taskfile.dev)
- **Template Building**: Packer for Windows Server 2025 templates

## Directory Structure and Conventions

### `/terraform/azure/global/`
- **Purpose**: Azure cloud global infrastructure management.
  This directory contains global resources shared across projects, such as:
  - **Terraform backend storage account**: Used for remote state storage for all Terraform projects.
  - **Azure Key Vault**: Stores shared secrets and credentials used by multiple projects.
- **Key Files**:
  - `main.tf` - Core Azure resources (Resource Group, Storage Account for backend, Key Vault for secrets)
  - `variables.tf` - Input variables with validation
  - `providers.tf` - Azure provider configuration with required providers
  - `backend.tf` - Remote state backend configuration
  - `azure.auto.tfvars` - Default configuration values
  - `azure.secrets.auto.tfvars` - Sensitive credentials (gitignored)
  - `backend.config` - Backend configuration (generated/gitignored)
  - `Taskfile.yml` - Task automation for Azure operations

### `/terraform/kubernetes/`
- **Purpose**: Main Terraform configuration for Kubernetes cluster deployment
- **Key Files**:
  - `main.tf` - Primary cluster configuration with node definitions
  - `variables.tf` - Input variables (non-sensitive)
  - `providers.tf` - Provider configurations and versions
  - `proxmox.auto.tfvars` - Proxmox connection settings
  - `proxmox.secrets.auto.tfvars` - Sensitive credentials (gitignored)

### `/terraform/kubernetes/modules/`
- **talos/**: Core Talos Linux cluster module
  - Machine configuration templates in `talos_machine_config_templates/`
  - Talos image factory integration in `talos_images/`
  - Proxmox VM provisioning
- **proxmox_csi_plugin/**: Proxmox CSI storage plugin
- **volumes/**: Persistent volume management

### `/k8s/`
- **Purpose**: Kubernetes manifests organized by GitOps patterns
- **Structure**:
  - `infra/` - Infrastructure components (networking, storage, controllers)
  - `apps/` - Application deployments (dev environment)
  - `sets/` - ArgoCD ApplicationSets for bulk application management

### `/packer/windows_server_2025/`
- **Purpose**: Windows Server 2025 template automation
- **Key Components**:
  - `windows_server_2025.pkr.hcl` - Main Packer configuration
  - `variables.pkr.hcl` - Variable definitions with validation
  - `.env` - Environment variables for credentials (gitignored)
  - `Taskfile.yml` - Task automation for builds
  - `build_files/` - Scripts and templates for Windows customization

## Coding Standards and Patterns

### Terraform
- **Module Structure**: Use consistent module patterns with `variables.tf`, `main.tf`, `outputs.tf`, `providers.tf`
- **Variable Validation**: Always include validation blocks for critical inputs (IP addresses, MAC addresses, node types)
- **Sensitive Data**: Keep sensitive variables in separate `.secrets.auto.tfvars` files (gitignored)
- **Resource Naming**: Use descriptive names with consistent prefixes or Azure CAF naming conventions
- **Provider Versions**: Pin provider versions for stability (use `~>` for minor version flexibility)
- **Default Values**: Provide sensible defaults or explicit null defaults to avoid interactive prompts
- **Conditional Resources**: Prefer `for_each` over `count` for conditional and multiple resources - it's more resilient to changes and provides better resource management

### Task Automation
- **Task Structure**: Use includes for modular task organization
- **Environment Variables**: Load from `.env` files using `dotenv` declaration
- **Working Directory**: Use `dir` parameter in includes to ensure proper execution context
- **Task Dependencies**: Use `deps` for task dependencies, `cmds` for sequential execution

### Kubernetes Manifests
- **Kustomization**: Use Kustomize for manifest templating and environment-specific overlays
- **Namespacing**: Follow consistent namespace patterns (`kube-system`, `argocd`, `monitoring`)
- **Labels**: Apply consistent labeling for pod security and topology awareness

### Packer Templates
- **Security**: Use environment variables for credentials, never hardcode secrets
- **Modularity**: Separate scripts by function (disable-services, remove-features, config-os)
- **Validation**: Always validate configurations before building
- **Restart Handling**: Use proper restart provisioners between major changes
- **Variable Validation**: Use numeric range validation instead of complex regex for simple cases
- **Storage Flexibility**: Always use variables for storage pools to maintain environment flexibility

## Environment-Specific Configurations

### Network Configuration
- **Cluster Network**: `192.168.65.0/24`
- **Control Plane IPs**: `192.168.65.110-112`
- **Worker Node IPs**: `192.168.65.120-122`
- **DNS Servers**: `192.168.65.30`, `192.168.65.40`
- **Gateway**: `192.168.65.1`
- **Domain**: `ad.ghiot.be`, `ghiot.be`

### Proxmox Configuration
- **Cluster Name**: `homelab`
- **Node**: `hsp-proxmox0`
- **Storage Pools**: `local` (ISOs), `local-lvm` (VMs)
- **Network Bridge**: `vmbr0`

## Security Practices

### Public Repository Security
This repository is designed to be publicly available on GitHub while remaining the actual working infrastructure code. All code must follow these security principles:

- **No Secrets in Code**: Never commit credentials, API keys, passwords, or tokens to version control
- **Safe Defaults**: Use placeholder values or null defaults for sensitive configuration
- **Template Pattern**: Provide `.template` files for sensitive configurations (`.env.template`, `*.secrets.auto.tfvars.template`)
- **Working Repository**: This is the actual infrastructure code in use, not a template - changes must maintain daily operational functionality
- **Network Information**: Private IP addresses and internal domain names are acceptable to expose as they don't create external security risks
- **Infrastructure Patterns**: Focus on infrastructure patterns and automation rather than specific credentials
- **Documentation**: Clearly document what users need to customize for their own environments

### What's Safe to Include:
- Internal IP ranges (192.168.x.x, 10.x.x.x)
- Internal domain names (ad.ghiot.be, homelab.local)
- Infrastructure architecture and patterns
- Configuration templates and examples
- Task automation and deployment scripts

### What Must Be Protected:
- API tokens and credentials
- External DNS providers credentials
- Service principal secrets
- SSH private keys
- TLS certificates and private keys
- Any external service credentials

### Credential Management
- **Environment Variables**: Use `PKR_VAR_*` pattern for Packer credentials
- **Git Ignore**: Always gitignore `.env`, `*.secrets.*` files
- **Templates**: Provide `.env.template` files for user guidance
- **Rotation**: Use API tokens instead of passwords where possible

### Access Control
- **Least Privilege**: Create dedicated service accounts (e.g., `kubernetes-csi@pve`)
- **Role-Based**: Use Proxmox roles for granular permissions
- **Certificate Management**: Enable automatic certificate rotation

## Common Patterns and Helpers

### Talos Configuration
```hcl
# Node definition pattern
"node-name" = {
  host_node        = "proxmox-node"
  machine_type     = "controlplane" # or "worker"
  ip              = "192.168.65.xxx"
  mac_address     = "BC:24:11:xx:xx:xx"
  vm_id           = "xxxxx"
  cpu             = 4
  ram_dedicated   = 4096
  update          = false
  primary_endpoint = false # true for one control plane node
}
```

### Task Automation Pattern
```yaml
# Include pattern for modular tasks
includes:
  module_name:
    taskfile: ./path/to/Taskfile.yml
    dir: ./path/to

# Environment loading
dotenv: ['.env']

# Task with validation
task_name:
  desc: "Description of what this task does"
  deps: [dependency_task]
  cmds:
    - echo "Executing task"
```

### Packer Environment Variables
```bash
# Credential pattern
PKR_VAR_proxmox_api_token="PVEAPIToken=user@pve!token=uuid"
PKR_VAR_proxmox_username="user@pve"
PKR_VAR_winrm_password="secure_password"
```

### Terraform for_each Patterns
```hcl
# Conditional resources - prefer for_each over count
resource "azurerm_resource" "example" {
  for_each = var.create_resource ? { "main" = var.resource_config } : {}
  # resource configuration
}

# Multiple resources from map
resource "azurerm_resource" "multiple" {
  for_each = var.resource_configs
  name     = each.key
  config   = each.value
}

# Multiple resources from set
resource "azurerm_resource" "from_set" {
  for_each = toset(var.resource_names)
  name     = each.value
}
```

## Troubleshooting Guidelines

### Common Issues
- **Talos Bootstrap**: Check endpoint connectivity and certificate validity
- **Packer Builds**: Verify VirtIO drivers and WinRM connectivity
- **ArgoCD Sync**: Check RBAC permissions and repository access
- **Storage Issues**: Validate CSI plugin configuration and Proxmox permissions

### Debugging Tools
- `task packer:setup` - Validate Packer environment
- `talosctl health` - Check cluster health
- `kubectl get nodes -o wide` - Verify node status
- `argocd app get <app-name>` - Check application sync status

## Dependencies and Tool Versions

### Required Tools
- **Terraform**: Infrastructure provisioning
- **Task**: Build automation (taskfile.dev)
- **Packer**: Template building
- **kubectl**: Kubernetes management
- **talosctl**: Talos cluster management
- **argocd**: GitOps application management
- **Azure CLI**: For Azure authentication and management

### Version Management
- **Terraform Providers**: See individual `providers.tf` files for pinned versions
- **Packer Plugins**: Defined in `packer/windows_server_2025/main.pkr.hcl`
- **Container Images**: Use specific tags in Kubernetes manifests, avoid `latest`
- **Tool Versions**: Let package managers handle tool versions unless specific compatibility required

## Development Workflow

1. **Infrastructure Changes**: Modify Terraform configurations, validate with `terraform plan`
2. **Application Deployment**: Update K8s manifests, let ArgoCD sync automatically
3. **Template Updates**: Use `task packer:validate` and `task packer:build` for Packer changes
4. **Testing**: Validate changes in dev environment before production
5. **CI/CD Validation**: All pull requests run pre-commit hooks and infrastructure validation

### Pre-commit and CI Pipeline

The repository uses pre-commit hooks and GitHub Actions for code quality:

- **Pre-commit Hooks**: Run locally and in CI to ensure code quality
  - Terraform formatting and validation
  - Packer validation
  - YAML linting (excluding k8s manifests)
  - Spell checking with cspell
  - Security scanning with gitleaks
  - Markdown linting

- **Infrastructure Validation**: Dedicated CI pipeline for infrastructure-specific checks
  - Terraform plan validation (with dummy values)
  - Packer template validation
  - Kubernetes manifest validation with kubeconform
  - Task file validation
  - Security scanning with Trivy

- **Setup Pre-commit Locally**:
  ```bash
  pip install pre-commit
  pre-commit install
  pre-commit run --all-files  # Run all hooks
  ```

## Best Practices for AI Assistance

- **Context Awareness**: Always consider the modular structure when suggesting changes
- **Security First**: Never suggest hardcoding credentials or bypassing security measures
- **Public Repository Safe**: Ensure all suggestions are safe for public GitHub repositories - no secrets, use template patterns
- **Working Infrastructure**: This is actual production infrastructure code - all changes must maintain operational functionality
- **Validation**: Recommend validation steps after any configuration changes
- **Documentation**: Update relevant documentation when making significant changes
- **Environment Consistency**: Maintain consistency between dev/prod environments
- **Gitleaks Configuration**: Never modify `.gitleaks.toml` without explicit validation and user approval. This file is critical for preventing secrets from being committed to the repository. Any changes to gitleaks rules or allowlists must be carefully reviewed to ensure they don't weaken security protections.

## Learning from Mistakes and Continuous Improvement

When errors or issues occur during development, document the solution in this instruction file to prevent repeating the same mistakes. This creates a knowledge base for future AI assistance.

### Common Mistakes and Solutions

#### Task Automation Issues
- **Mistake**: Using `dotenv` in both main Taskfile and included Taskfiles causes conflicts
- **Solution**: Only declare `dotenv` in the main Taskfile.yml, not in included task files. The environment variables are automatically inherited by included tasks.

#### Packer Template Issues
- **Mistake**: Hardcoding storage pool names in Packer configurations
- **Solution**: Always use variables for storage pools (`var.disk_storage`, `var.iso_storage`, `var.efi_storage`) to maintain flexibility across environments.

#### Security Credential Management
- **Mistake**: Storing sensitive credentials in `.tfvars` files that get committed to version control
- **Solution**: Use `.env` files with `PKR_VAR_*` pattern for Packer, and `.secrets.auto.tfvars` files for Terraform (both gitignored).

#### Variable Validation Issues
- **Mistake**: Using complex regex validation for simple numeric ranges in Packer/Terraform
- **Solution**: Use simple numeric range validation (`var.vm_id >= 100 && var.vm_id <= 999999999`) instead of regex patterns. Regex validation can be fragile and harder to debug.

#### Azure Terraform Configuration
- **Mistake**: Not handling null values in conditional resources, causing validation errors
- **Solution**: Always provide default values (including `null`) for optional variables and use conditional data sources with `count` parameter to avoid resource creation when not needed.

#### Backend State Management
- **Mistake**: Hardcoding backend configuration or not handling new vs existing infrastructure scenarios
- **Solution**: Use conditional initialization in Task files to check for `backend.config` existence and provide clear guidance for both new and existing infrastructure setups.

#### State Validation and Provisioner Resources
- **Mistake**: Using `null_resource` with provisioners for validation or state management
- **Solution**: Always use `terraform_data` instead of `null_resource`. The `terraform_data` resource is the modern Terraform pattern for managing state and running provisioners. Example:
  ```hcl
  # ✅ CORRECT - Use terraform_data
  resource "terraform_data" "validate_configuration" {
    input = local.validation_error
    provisioner "local-exec" {
      command = self.input != "" ? "echo '${self.input}' && exit 1" : "echo 'Valid'"
      interpreter = ["/bin/sh", "-c"]
    }
  }

  # ❌ WRONG - Don't use null_resource
  resource "null_resource" "validate_configuration" {
    triggers = { validation_error = local.validation_error }
    provisioner "local-exec" { command = "..." }
  }
  ```
  Benefits of `terraform_data`: Better semantics, built-in state management, clearer intent, and improved compatibility with modern Terraform versions.

### Instructions for Adding New Mistakes/Solutions

When encountering a new mistake or issue:

1. **Document the Problem**: Clearly describe what went wrong and why
2. **Provide the Solution**: Include the exact steps or code changes that fixed the issue
3. **Add Prevention Tips**: Suggest how to avoid this mistake in the future
4. **Update This Section**: Add the new mistake/solution pair to the list above

This approach ensures that the AI assistant becomes more effective over time by learning from past experiences and avoiding repeated errors.
