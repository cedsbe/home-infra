locals {
  azurecaf_prefixes = [var.project_name]
  azurecaf_suffixes = []
}

#region Resource Group
# Resource Group Naming
resource "azurecaf_name" "rg" {
  name          = "landing"
  resource_type = "azurerm_resource_group"
  prefixes      = local.azurecaf_prefixes
  suffixes      = local.azurecaf_suffixes
  random_length = 0
  clean_input   = true
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg.result
  location = var.location
  tags     = var.tags
}
#endregion Resource Group

#region Static Web App
# Static Web App Naming
resource "azurecaf_name" "static_web_app" {
  name          = "landing"
  use_slug      = false
  resource_type = "general"
  prefixes      = concat(local.azurecaf_prefixes, ["swa"])
  suffixes      = local.azurecaf_suffixes
  random_length = 0
  clean_input   = true
}

#Static Web App
resource "azurerm_static_web_app" "static_web_app" {
  name                = azurecaf_name.static_web_app.result
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_tier            = "Free"
  sku_size            = "Free"

  repository_url    = "https://github.com/cedsbe/personal-landing-page"
  repository_branch = "main"
  repository_token  = var.github_token

  tags = var.tags
}

# Static Web App Custom Domain
resource "azurerm_static_web_app_custom_domain" "custom_domain" {
  static_web_app_id = azurerm_static_web_app.static_web_app.id
  domain_name       = var.custom_domain_name
  validation_type   = "cname-delegation"
}
#endregion Static Web App
