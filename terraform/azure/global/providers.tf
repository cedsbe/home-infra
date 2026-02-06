terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.58.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "3.7.0"
    }

    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.31"
    }

    dns = {
      source  = "hashicorp/dns"
      version = "3.5.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.6.2"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }
  }

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  resource_provider_registrations = "core"
}

provider "azuread" {
  tenant_id = var.tenant_id
}
