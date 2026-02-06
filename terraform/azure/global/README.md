# Azure Terraform Configuration

This directory contains Terraform configuration for global Azure resources shared across projects in the home-infra environment.

## Overview

This configuration sets up global Azure infrastructure, including:

- **Resource Group**: Container for all shared resources
- **Storage Account**: Centralized backend state storage for all Terraform projects
- **Key Vault**: Shared secrets management for use across multiple projects, with network restrictions
- **Dynamic DNS Resolution**: Resolves home network FQDN for security rules
- **n8n Outlook Integration**: Azure AD app registration for n8n to access Microsoft Outlook via OAuth2

These resources are intended to be reused by other infrastructure modules and projects. The configuration uses Azure CAF (Cloud Adoption Framework) naming conventions and includes remote state management.

## n8n Outlook Integration

This configuration creates an Azure AD application registration and service principal to enable n8n to access Microsoft Outlook via OAuth2. This follows the [n8n Microsoft OAuth2 documentation](https://docs.n8n.io/integrations/builtin/credentials/microsoft/#using-oauth2).

### Features

- **Multi-tenant Support**: Configured for Azure AD and personal Microsoft accounts
- **Graph API Scopes**: Pre-configured with necessary permissions (Mail.Read, Mail.ReadWrite, Mail.Send, User.Read, offline_access)
- **Secure Storage**: Client ID and secret stored in Azure Key Vault
- **Service Principal**: Automated service principal creation

### Setup Instructions

1. **Configure Redirect URI**:
   In `azure.secrets.auto.tfvars`, add your n8n OAuth callback URL:

   ```hcl
   n8n_outlook_redirect_uris = [
     "https://your-n8n-instance.com/rest/oauth2-credential/callback"
   ]
   ```

2. **Deploy the App Registration**:

   ```bash
   task azure:apply
   ```

3. **Get Credentials**:

   ```bash
   # Display all outputs including n8n configuration
   terraform output

   # Or retrieve specific values
   terraform output n8n_outlook_application_id
   terraform output n8n_outlook_tenant_id

   # Retrieve client secret from Azure Key Vault
   az keyvault secret show \
     --vault-name $(terraform output -raw resource_group_name | sed 's/-rg$/-kv/') \
     --name n8n-outlook-client-secret \
     --query value -o tsv
   ```

4. **Configure n8n**:
   - Create a new Microsoft OAuth2 credential in n8n
   - Use the Application (Client) ID from terraform output
   - Use the Tenant ID from terraform output
   - Retrieve the Client Secret from Azure Key Vault (command above)
   - Complete the OAuth flow in n8n

5. **Admin Consent** (if required):
   For organizational Microsoft accounts, an admin may need to grant consent. See [Microsoft Entra documentation](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/grant-admin-consent).

### API Permissions

The app registration includes the following Microsoft Graph API delegated permissions:

- **Mail.Read**: Read user mailboxes
- **Mail.ReadWrite**: Read and write user mailboxes
- **Mail.Send**: Send mail as a user
- **User.Read**: Sign in and read user profile
- **offline_access**: Maintain access to data

## Key Features

- **Azure CAF Naming**: Consistent resource naming using the `azurecaf` provider
- **Remote State Backend**: Self-managed storage account for Terraform state
- **DNS Integration**: Resolves dynamic DNS hostnames for network access control
- **Security**: Key Vault with network restrictions based on home IP
- **Home Integration**: Designed to work with existing home infrastructure

## Prerequisites

### Azure CLI Installation

Install Azure CLI and authenticate:

```bash
# Install Azure CLI (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Set subscription (if you have multiple)
az account set --subscription "your-subscription-name-or-id"

# Verify current account
az account show
```

### Service Principal (Optional)

For automated deployments, create a service principal:

```bash
# Create service principal
az ad sp create-for-rbac --name "terraform-home-infra" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
```

## Configuration

### 1. Copy Configuration Files

```bash
# Secrets template already exists - customize with your values
cp azure.secrets.auto.tfvars.template azure.secrets.auto.tfvars

# The azure.auto.tfvars file contains default configuration
```

### 2. Customize Variables

Edit `azure.auto.tfvars`:

```hcl
location     = "West Europe"  # West Europe or North Europe
project_name = "home-infra"   # Your project name

tags = {
  Project    = "home-infra"
  ManagedBy  = "Terraform"
  Repository = "home-infra"
}
```

### 3. Set Required Variables

Edit `azure.secrets.auto.tfvars`:

```hcl
# Your dynamic DNS hostname (for Key Vault network restrictions)
dynamic_dns_home_fqdn = "your-home.dyndns.org"

# Optional: If using service principal authentication
# subscription_id = "your-subscription-id"
# tenant_id       = "your-tenant-id"
```

## Usage

### Task-based Workflow (Recommended)

```bash
# Initialize Terraform (handles backend configuration automatically)
task azure:init

# Validate configuration
task azure:validate

# Plan deployment
task azure:plan

# Deploy infrastructure
task azure:apply

# Check resources
task azure:resources
```

### Backend State Management

This configuration uses a self-managed Azure Storage Account for Terraform state:

#### For NEW Infrastructure:

1. Ensure `backend.tf` has the backend block commented out initially
2. Run `task azure:init` (initializes without backend)
3. Run `task azure:apply` (creates storage account)
4. Create `backend.config` with storage account details
5. Uncomment backend block in `backend.tf`
6. Re-run `task azure:init` with `-migrate-state` to move state to remote backend

#### For EXISTING Infrastructure:

1. Ensure you have `backend.config` with correct storage account details
2. Ensure backend block in `backend.tf` is uncommented
3. Run `task azure:init` (automatically uses backend configuration)

### Manual Terraform Commands

```bash
# Initialize with backend configuration
terraform init -backend-config=./backend.config

# Plan without backend (for new infrastructure)
terraform init
terraform plan
terraform apply
```

## Resource Naming Convention

Resources follow Azure CAF naming conventions using the `azurecaf` provider:

- **Resource Group**: Generated by azurecaf for `azurerm_resource_group`
- **Storage Account**: Generated by azurecaf for `azurerm_storage_account` (with random suffix)
- **Key Vault**: Generated by azurecaf for `azurerm_key_vault` (with random suffix)

All resources include the project name as prefix and follow Azure naming best practices.

## File Structure

```
terraform/azure/global/
├── main.tf                           # Main infrastructure resources
├── variables.tf                      # Variable definitions with validation
├── providers.tf                      # Provider requirements and configuration
├── outputs.tf                        # Resource outputs
├── backend.tf                        # Remote state backend configuration
├── azure.auto.tfvars                 # Default configuration values
├── azure.secrets.auto.tfvars.template # Template for sensitive variables
├── backend.config.template           # Template for backend configuration
├── Taskfile.yml                      # Task automation
└── README.md                         # This file
```

## Security Considerations

1. **Secrets Management**: Never commit `azure.secrets.auto.tfvars` or `backend.config` to version control
2. **Key Vault Access**: Uses RBAC authorization and network restrictions
3. **Network Security**: Key Vault only accessible from resolved home IP address
4. **State Security**: Remote state stored in Azure Storage with proper access controls
5. **DNS Resolution**: Automatically resolves dynamic DNS to current IP for access rules

## Required Providers

This configuration uses several Terraform providers:

- **azurerm** (~> 4.0): Azure Resource Manager provider
- **azurecaf** (~> 1.2): Azure CAF naming conventions
- **dns** (~> 3.0): DNS resolution for dynamic hostnames
- **local** (~> 2.0): Local file operations

## Adding Resources

To add new Azure resources:

1. Add the resource configuration to `main.tf` with appropriate azurecaf naming
2. Add any new variables to `variables.tf` with validation
3. Add outputs to `outputs.tf` if needed
4. Update this README with documentation
5. Use Task commands for deployment: `task azure:plan` and `task azure:apply`

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Verify Azure CLI login with `az account show`
2. **Backend Configuration**: Ensure `backend.config` exists for existing infrastructure
3. **DNS Resolution**: Verify your dynamic DNS hostname resolves correctly
4. **Naming Conflicts**: Azure resource names must be globally unique (storage accounts, key vaults)
5. **Network Access**: Key Vault network restrictions may block access if IP changes

### Useful Commands

```bash
# Check current Azure context
task azure:azure:account

# List available Azure regions
task azure:azure:locations

# Check created resources
task azure:azure:resources

# Validate Terraform configuration
task azure:validate

# Show Terraform outputs
task azure:output
```

### Backend State Issues

If you have backend state issues:

1. **New Infrastructure**: Comment out backend block in `backend.tf`, run init, apply, then migrate
2. **Existing Infrastructure**: Ensure `backend.config` has correct storage account details
3. **State Migration**: Use `terraform init -migrate-state` when moving between backends

## Integration with Home Infrastructure

This Azure configuration is designed to complement the existing Proxmox-based home infrastructure:

- **Hybrid Cloud**: Azure for cloud services, Proxmox for local workloads
- **Global State Management**: Centralized Terraform state storage in Azure, shared by all Terraform projects
- **Shared Secrets Management**: Azure Key Vault for secrets used across multiple environments and modules
- **Network Integration**: Dynamic DNS resolution for home network access
- **Task Integration**: Seamless integration with project's Task-based workflow

## Cost Optimization

- **Storage**: Uses Standard LRS for cost efficiency
- **Key Vault**: Standard tier for basic secret management
- **Resource Management**: Minimal resource footprint focused on essential services
- **Dynamic Scaling**: Resources can be extended based on actual needs

## Available Task Commands

All Azure operations are available through Task commands:

```bash
# Infrastructure Management
task azure:init      # Initialize Terraform
task azure:validate  # Validate configuration
task azure:plan      # Plan changes
task azure:apply     # Apply changes
task azure:destroy   # Destroy infrastructure
task azure:output    # Show outputs

# Azure CLI Operations
task azure:azure:login     # Login to Azure
task azure:azure:account   # Show account info
task azure:azure:locations # List regions
task azure:azure:resources # List resources

# Utilities
task azure:format    # Format Terraform files
task azure:clean     # Clean Terraform cache
task azure:setup     # Setup configuration files
task azure:check     # Check setup and authentication
```
