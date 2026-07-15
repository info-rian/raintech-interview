terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.40.0"
    }
    # azapi enables the Azure SQL free offer, which azurerm does not yet expose.
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0.0"
    }
  }
}
