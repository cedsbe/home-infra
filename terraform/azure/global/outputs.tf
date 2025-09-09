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
