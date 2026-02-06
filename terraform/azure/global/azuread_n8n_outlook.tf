# Azure AD App Registration for n8n Outlook Integration
# This app registration enables n8n to access Microsoft Outlook via OAuth2
# Reference: https://docs.n8n.io/integrations/builtin/credentials/microsoft/#using-oauth2

#region Azure AD Application
resource "azuread_application" "n8n_outlook" {
  display_name = "n8n Outlook Integration"
  description  = "OAuth2 application for n8n to access Microsoft Outlook via Graph API"

  # Multi-tenant and personal Microsoft accounts support as required by n8n
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"

  # API configuration - required for multi-tenant apps
  api {
    requested_access_token_version = 2
  }

  # Web redirect URI - Update this with your actual n8n OAuth callback URL
  # Format: https://<your-n8n-instance>/rest/oauth2-credential/callback
  web {
    redirect_uris = var.n8n_outlook_redirect_uris

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = false
    }
  }

  # Required Microsoft Graph API permissions for Outlook
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    # Delegated permissions for user mailbox access
    resource_access {
      id   = "570282fd-fa5c-430d-a7fd-fc8dc98a9dca" # Mail.Read
      type = "Scope"
    }

    resource_access {
      id   = "024d486e-b451-40bb-833d-3e66d98c5c73" # Mail.ReadWrite
      type = "Scope"
    }

    resource_access {
      id   = "e383f46e-2787-4529-855e-0e479a3ffac0" # Mail.Send
      type = "Scope"
    }

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }

    resource_access {
      id   = "7427e0e9-2fba-42fe-b0c0-848c9e6a8182" # offline_access
      type = "Scope"
    }
  }

  tags = concat(
    ["n8n", "outlook", "email", "integration"],
    [for k, v in var.tags : "${k}:${v}"]
  )
}

#endregion Azure AD Application

#region Service Principal
# Create service principal for the application
resource "azuread_service_principal" "n8n_outlook" {
  client_id = azuread_application.n8n_outlook.client_id

  # Use the application's identifier URI as the preferred single sign-on mode
  preferred_single_sign_on_mode = "oidc"

  tags = concat(
    ["n8n", "outlook", "email", "integration"],
    [for k, v in var.tags : "${k}:${v}"]
  )
}

#endregion Service Principal

#region Application Password (Client Secret)
# Generate client secret for OAuth2 authentication
resource "azuread_application_password" "n8n_outlook" {
  application_id = azuread_application.n8n_outlook.id
  display_name   = "n8n Outlook OAuth2 Secret"

  # Rotate the password when this map changes
  rotate_when_changed = {
    rotation = "v1" # Increment this value to force password rotation
  }

  lifecycle {
    # Ignore changes to end_date to prevent unnecessary recreations
    ignore_changes = [end_date]
  }
}

#endregion Application Password (Client Secret)

#region Key Vault Secrets
# Store Application (Client) ID in Key Vault
resource "azurerm_key_vault_secret" "n8n_outlook_client_id" {
  name         = "n8n-outlook-client-id"
  value        = azuread_application.n8n_outlook.client_id
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags
}

# Store Client Secret in Key Vault
resource "azurerm_key_vault_secret" "n8n_outlook_client_secret" {
  name         = "n8n-outlook-client-secret"
  value        = azuread_application_password.n8n_outlook.value
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags
}

#endregion Key Vault Secrets
