data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

data "http" "my_ip" {
  url = "https://api.ipify.org?format=json"
}

locals {
  current_ip = jsondecode(data.http.my_ip.response_body).ip

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  tenant_id = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  enable_rbac_authorization = true

  purge_protection_enabled   = true
  soft_delete_retention_days = 90

  public_network_access_enabled = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"

    ip_rules = concat(
      [local.current_ip],
      var.allowed_ips
    )
  }

  tags = local.tags
}

