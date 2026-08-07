terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.2"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }

  }
}

provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

}


data "http" "my_ip" {
  url = "https://api.ipify.org?format=json"
}


# ----------------------------
# Resource group
# ----------------------------
data "azurerm_resource_group" "rg" {
  name = "<your_domain>-k8s-cluster_RG"
}

# ----------------------------
# Locals (naming + IP)
# ----------------------------
locals {
  storage_account_name = "<your_domain>blobtfstate"
  my_ip                = "${jsondecode(data.http.my_ip.response_body).ip}/30"


  allowed_ips = [
    "insert-on-prem-cluster-IP/30",

  ]
  ip_rules = concat([local.my_ip], local.allowed_ips)
}

# ----------------------------
# Storage account (TF STATE)
# ----------------------------
resource "azurerm_storage_account" "tfstate" {
  name                = local.storage_account_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 7
    }

  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = local.ip_rules
  }

  tags = {
    purpose     = "terraform-state"
    environment = "<your_domain>-prd"
    managed_by  = "terraform"
  }
}

# ----------------------------
# Container
# ----------------------------
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
