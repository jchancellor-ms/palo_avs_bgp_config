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

provider "azurerm" {
  features {
  }
}


provider "panos" {
    alias = "firewall_1"
    hostname = data.azurerm_public_ip.fw1.ip_address
    username = var.admin_username
    password = ephemeral.azurerm_key_vault_secret.firewall_password["vm1"].value
    protocol = "https"
    skip_verify_certificate = true
}

provider "panos" {
    alias = "firewall_2"
    hostname = data.azurerm_public_ip.fw2.ip_address
    username = var.admin_username
    password = ephemeral.azurerm_key_vault_secret.firewall_password["vm2"].value
    protocol = "https"
    skip_verify_certificate = true
}

