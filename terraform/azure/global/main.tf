locals {
  azurecaf_prefixes = [var.project_name]
  azurecaf_suffixes = []
}

# Data source to get current Azure configuration
data "azurerm_client_config" "current" {}

#region DNS Resolve for Dynamic DNS
data "dns_a_record_set" "dynamic_dns_home" {
  count = var.dynamic_dns_home_fqdn != null ? 1 : 0
  host  = var.dynamic_dns_home_fqdn
}

locals {
  dynamic_dns_home_ip = var.dynamic_dns_home_fqdn != null && length(data.dns_a_record_set.dynamic_dns_home) > 0 ? (
    length(data.dns_a_record_set.dynamic_dns_home[0].addrs) > 0 ? data.dns_a_record_set.dynamic_dns_home[0].addrs[0] : null
  ) : null
}

#endregion DNS Resolve for Dynamic DNS

#region Resource Group
# Resource Group Naming
resource "azurecaf_name" "main" {
  name          = "main"
  resource_type = "azurerm_resource_group"
  prefixes      = local.azurecaf_prefixes
  suffixes      = local.azurecaf_suffixes
  random_length = 0
  clean_input   = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.main.result
  location = var.location
  tags     = var.tags
}
#endregion Resource Group

#region Storage Account for Terraform backend
# Storage Account for Terraform backend
resource "azurecaf_name" "backend" {
  name          = "tf-backend"
  resource_type = "azurerm_storage_account"
  prefixes      = local.azurecaf_prefixes
  suffixes      = local.azurecaf_suffixes
  random_length = 5
  clean_input   = true
}

resource "azurerm_storage_account" "backend" {
  name                     = azurecaf_name.backend.result
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Add a "tf-backend" container
resource "azurerm_storage_container" "tf_backend" {
  name                  = "tf-backend"
  storage_account_id    = azurerm_storage_account.backend.id
  container_access_type = "private"
}

# Create the config file for terraform backend
resource "local_file" "backend_config" {
  content    = <<-EOF
    storage_account_name = "${azurerm_storage_account.backend.name}"
    container_name       = "${azurerm_storage_container.tf_backend.name}"
    key                  = "azure.tfstate"
    EOF
  filename   = "${path.module}/backend.config"
  depends_on = [azurerm_storage_container.tf_backend]
}

#endregion Storage Account for Terraform backend


#region Key Vault for secrets management
# Key Vault Naming
resource "azurecaf_name" "key_vault" {
  name          = "main"
  resource_type = "azurerm_key_vault"
  prefixes      = local.azurecaf_prefixes
  suffixes      = local.azurecaf_suffixes
  random_length = 5
  clean_input   = true
}

# Key Vault for secrets management
resource "azurerm_key_vault" "main" {
  name                = azurecaf_name.key_vault.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags

  sku_name                  = "standard"
  enable_rbac_authorization = true
  purge_protection_enabled  = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = local.dynamic_dns_home_ip != null ? [local.dynamic_dns_home_ip] : []
  }

}
