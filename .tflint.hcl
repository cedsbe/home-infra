config {
  call_module_type = "local"
  force = false
  disabled_by_default = false
}

plugin "terraform" {
  enabled = true
  preset  = "all"
}

plugin "azurerm" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

rule "azurerm_resource_missing_tags" {
  enabled = true
  tags    = []
}
