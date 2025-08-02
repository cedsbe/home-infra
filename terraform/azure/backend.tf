# Backend configuration for remote state storage
# 
# For NEW infrastructure: Comment out this block initially
# For EXISTING infrastructure: Ensure this block is uncommented

terraform {
  backend "azurerm" {
    use_azuread_auth = true
  }
}
