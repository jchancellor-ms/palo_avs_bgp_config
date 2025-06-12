terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.115, < 5.0"
    }
    panos = {
      source = "PaloAltoNetworks/panos"
      version = "~>2.0"
    }
  }
}