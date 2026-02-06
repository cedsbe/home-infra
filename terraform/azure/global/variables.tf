variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"

  validation {
    condition = contains([
      "West Europe",
      "North Europe",
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "home-infra"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "Project name must be 3-20 characters, lowercase letters, numbers, and hyphens only."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project    = "home-infra"
    ManagedBy  = "Terraform"
    Repository = "home-infra"
  }
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = null
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = null
  sensitive   = true
}

variable "dynamic_dns_home_fqdn" {
  description = "Dynamic DNS FQDN for home network (required for Key Vault network access rules)"
  type        = string
  default     = null

  validation {
    condition     = var.dynamic_dns_home_fqdn == null || can(regex("^([a-z0-9-]+\\.)+[a-z]{2,}$", var.dynamic_dns_home_fqdn))
    error_message = "Dynamic DNS FQDN must be a valid domain name or null."
  }
}

variable "n8n_outlook_redirect_uris" {
  description = "OAuth2 redirect URIs for n8n Outlook integration (format: https://<n8n-instance>/rest/oauth2-credential/callback)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for uri in var.n8n_outlook_redirect_uris : can(regex("^https://[a-zA-Z0-9._-]+(/.*)?$", uri))
    ])
    error_message = "All redirect URIs must be valid HTTPS URLs."
  }
}
