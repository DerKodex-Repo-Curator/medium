terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.2"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "<your_domain>-k8s-cluster_RG"
    storage_account_name = "<your_domain>blobtfstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

