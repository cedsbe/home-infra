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

variable "github_token" {
  description = "GitHub token for CI/CD"
  type        = string
  default     = null
  sensitive   = true
}

variable "custom_domain_name" {
  description = "The custom domain name to assign to the Static Web App (e.g. www.example.com)"
  type        = string
  validation {
    condition     = length(var.custom_domain_name) > 0
    error_message = "custom_domain_name must not be empty."
  }
}
