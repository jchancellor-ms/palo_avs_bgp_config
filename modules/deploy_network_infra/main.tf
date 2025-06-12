locals {
    vnet_name = "${var.name_prefix}-firewall-vnet"
    route_table_name = "${var.name_prefix}-untrust-route-table"
    key_vault_name = "${var.name_prefix}-keyvault-${random_string.name_suffix.result}"
    
    subnets = {
        management = {
            name             = "${var.name_prefix}-mgmt-subnet"
            address_prefixes = [cidrsubnet(var.firewall_vnet_address_space, 3, 0)]
            route_table = {
              id = module.untrust_route_table.resource_id
            }
            network_security_group = {
                id = module.nsg.resource_id
            }
        }
        trust = {
            name             = "${var.name_prefix}-trust-subnet"
            address_prefixes = [cidrsubnet(var.firewall_vnet_address_space, 3, 1)]
        }
        untrust = {
            name             = "${var.name_prefix}-untrust-subnet"
            address_prefixes = [cidrsubnet(var.firewall_vnet_address_space, 3, 2)]
            route_table = {
                id = module.untrust_route_table.resource_id
            }
            network_security_group = {
                id = module.nsg.resource_id
            }
        }
        trust_lb = {
            name             = "${var.name_prefix}-trust-lb-subnet"
            address_prefixes = [cidrsubnet(var.firewall_vnet_address_space, 3, 3)]
        }
    }
}

module "untrust_route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.4.1"

  resource_group_name = var.resource_group_name
  name                = local.route_table_name
  location            = var.location

  bgp_route_propagation_enabled = false

  routes = {
    default = {
      name                   = "default"
      address_prefix         = "0.0.0.0/0"
      next_hop_type         = "Internet"
    }
  }
}

module "prod_firewall_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.7.1"

  resource_group_name = var.resource_group_name
  address_space       = [var.firewall_vnet_address_space]
  name                = local.vnet_name
  location            = var.location
  enable_telemetry           = var.enable_telemetry

  subnets = local.subnets

  peerings = {
    peertohub = {
      name                                  = "${local.vnet_name}-to-hub"
      remote_virtual_network_resource_id    = var.hub_virtual_network_resource_id
      allow_forwarded_traffic               = true
      allow_gateway_transit                 = false
      allow_virtual_network_access          = true
      do_not_verify_remote_gateways         = true
      enable_only_ipv6_peering              = false
      use_remote_gateways                   = true
      create_reverse_peering                = true
      reverse_name                          = "hub-to-${local.vnet_name}"
      reverse_allow_forwarded_traffic       = true
      reverse_allow_gateway_transit         = true
      reverse_allow_virtual_network_access  = true
      reverse_do_not_verify_remote_gateways = true
      reverse_enable_only_ipv6_peering      = false
      reverse_use_remote_gateways           = false
    }
  }
}

module "nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.4.0"

  resource_group_name = var.resource_group_name
  name                = "${var.name_prefix}-firewall-nsg"
  location            = var.location

  security_rules = local.nsg_rules
}

resource "random_string" "name_suffix" {
  length  = 4
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}

module "avm_res_keyvault_vault" {
  source                      = "Azure/avm-res-keyvault-vault/azurerm"
  version                     = "=0.10.0"
  enable_telemetry           = var.enable_telemetry
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  name                        = local.key_vault_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  enabled_for_disk_encryption = true
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  role_assignments = {
    deployment_user_secrets = { #give the deployment user access to secrets
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  wait_for_rbac_before_key_operations = {
    create = "60s"
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
}

