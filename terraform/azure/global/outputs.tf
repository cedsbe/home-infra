output "current_subscription_id" {
  description = "Current Azure subscription ID"
  value       = data.azurerm_client_config.current.subscription_id
  sensitive   = true
}

output "current_tenant_id" {
  description = "Current Azure tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
  sensitive   = true
}
output "resource_group_name" {
  description = "Name of the resource group created for the infrastructure"
  value       = azurerm_resource_group.main.name
}

output "n8n_outlook_application_id" {
  description = "Azure AD Application (Client) ID for n8n Outlook integration"
  value       = length(azuread_application.n8n_outlook) > 0 ? azuread_application.n8n_outlook["main"].client_id : null
  sensitive   = false
}

output "n8n_outlook_tenant_id" {
  description = "Azure Tenant ID for n8n Outlook integration"
  value       = length(azuread_application.n8n_outlook) > 0 ? data.azurerm_client_config.current.tenant_id : null
  sensitive   = false
}

output "n8n_outlook_key_vault_secret_name" {
  description = "Azure Key Vault secret name for n8n Outlook client secret"
  value       = length(azuread_application.n8n_outlook) > 0 ? "n8n-outlook-client-secret" : null
}
