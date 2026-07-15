terraform {
  required_version = "~> 1.13"

  # Remote state is configured out-of-band:
  #   terraform init -backend-config=backend.config
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.80.0"
    }
    # Enables the Azure SQL free offer (property not yet in azurerm).
    azapi = {
      source  = "Azure/azapi"
      version = "= 2.10.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azapi" {
  subscription_id = var.subscription_id
}
