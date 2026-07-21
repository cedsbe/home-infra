# Azure AD App Registration for GitHub OIDC Integration
# This app registration enables GitHub Actions to authenticate with Azure AD using OpenID Connect (OIDC)
# Reference: https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure

#region Azure AD Application
resource "azuread_application" "github_oidc" {
  display_name = "GitHub OIDC Integration"
  description  = "OIDC application for GitHub Actions to authenticate with Azure AD"

  tags = concat(
    ["github_oidc"],
    [for k, v in var.tags : "${k}:${v}"]
  )
}
#endregion Azure AD Application

#region Service Principal
# Create service principal for the application
resource "azuread_service_principal" "github_oidc" {
  client_id = azuread_application.github_oidc.client_id

  tags = concat(
    ["github_oidc"],
    [for k, v in var.tags : "${k}:${v}"]
  )
}
#endregion Service Principal

#region Federated Identity Credential
# Create federated identity credential for GitHub OIDC
resource "azuread_application_federated_identity_credential" "github_oidc_pr" {
  application_id = azuread_application.github_oidc.id
  display_name   = "github-oidc-home-infra-pr"
  description    = "Federated identity credential for GitHub cedsbe/home-infra pull requests"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:cedsbe@8707686/home-infra@1032130197:pull_request"
}

resource "azuread_application_federated_identity_credential" "github_oidc_main" {
  application_id = azuread_application.github_oidc.id
  display_name   = "github-oidc-home-infra-main"
  description    = "Federated identity credential for GitHub cedsbe/home-infra main branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:cedsbe@8707686/home-infra@1032130197:ref:refs/heads/main"
}
#endregion Federated Identity Credential

#region Azure RBAC Role Assignments
# Subscription-scope Contributor: manages resource groups, storage accounts, key
# vault, and static web app resources across the azure-global and azure-landing
# Terraform workspaces.
resource "azurerm_role_assignment" "github_oidc_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_oidc.object_id
}

# Storage Blob Data Contributor on the Terraform backend storage account: required
# because backend.tf uses `use_azuread_auth = true`, so state access goes through
# Azure AD RBAC on the blob data plane rather than the storage account access key.
resource "azurerm_role_assignment" "github_oidc_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.backend.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_oidc.object_id
}

# Key Vault Secrets Officer on the shared key vault: required because
# rbac_authorization_enabled = true means Contributor (control plane) does not
# grant secret read/write access; a data-plane role is needed separately.
resource "azurerm_role_assignment" "github_oidc_key_vault_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azuread_service_principal.github_oidc.object_id
}
#endregion Azure RBAC Role Assignments

#region Entra ID Directory Role Assignment
# Application Administrator: required because this workspace manages
# azuread_application / azuread_service_principal / federated identity credential /
# application password resources, including this app's own federated credentials.
# Azure RBAC role assignments above do not cover Microsoft Entra ID object management.
resource "azuread_directory_role" "application_administrator" {
  display_name = "Application Administrator"
}

resource "azuread_directory_role_assignment" "github_oidc_application_administrator" {
  role_id             = azuread_directory_role.application_administrator.template_id
  principal_object_id = azuread_service_principal.github_oidc.object_id
}
#endregion Entra ID Directory Role Assignment
