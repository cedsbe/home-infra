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
  - Machine configuration templates in `talos_machine_config/`
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
- **Sensitive Data**: Keep sensitive variables in separate `.secrets.auto.tfvars` files
- **Resource Naming**: Use descriptive names with consistent prefixes (e.g., `hsv-kctrl0`, `hsv-kwork0`)
- **Provider Versions**: Pin provider versions for stability

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
- **Task**: Build automation
- **Packer**: Template building
- **kubectl**: Kubernetes management
- **talosctl**: Talos cluster management
- **argocd**: GitOps application management

### Key Versions
- **Talos Linux**: v1.9.0
- **Cilium**: v1.16.5
- **Terraform Providers**: See `providers.tf` files for exact versions
- **Packer Plugins**: windows-update v0.16.10, proxmox v1.2.1

## Development Workflow

1. **Infrastructure Changes**: Modify Terraform configurations, validate with `terraform plan`
2. **Application Deployment**: Update K8s manifests, let ArgoCD sync automatically
3. **Template Updates**: Use `task packer:validate` and `task packer:build` for Packer changes
4. **Testing**: Validate changes in dev environment before production

## Best Practices for AI Assistance

- **Context Awareness**: Always consider the modular structure when suggesting changes
- **Security First**: Never suggest hardcoding credentials or bypassing security measures
- **Validation**: Recommend validation steps after any configuration changes
- **Documentation**: Update relevant documentation when making significant changes
- **Environment Consistency**: Maintain consistency between dev/prod environments

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

#### Script File References
- **Mistake**: Referencing renamed script files without updating all references
- **Solution**: When renaming files like PowerShell scripts, check all references in Packer configurations, Taskfiles, and validation scripts.

### Instructions for Adding New Mistakes/Solutions

When encountering a new mistake or issue:

1. **Document the Problem**: Clearly describe what went wrong and why
2. **Provide the Solution**: Include the exact steps or code changes that fixed the issue
3. **Add Prevention Tips**: Suggest how to avoid this mistake in the future
4. **Update This Section**: Add the new mistake/solution pair to the list above

This approach ensures that the AI assistant becomes more effective over time by learning from past experiences and avoiding repeated errors.
