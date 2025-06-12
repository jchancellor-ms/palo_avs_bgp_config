resource "azurerm_resource_group" "firewall_rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_resource_group" "existing_firewall_rg" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.firewall_rg[0].name : data.azurerm_resource_group.existing_firewall_rg[0].name
  resource_group_id   = var.create_resource_group ? azurerm_resource_group.firewall_rg[0].id : data.azurerm_resource_group.existing_firewall_rg[0].id
  location            = var.create_resource_group ? azurerm_resource_group.firewall_rg[0].location : data.azurerm_resource_group.existing_firewall_rg[0].location
}

module "deploy_network_infra" {
  source = "../modules/deploy_network_infra"

  resource_group_name         = local.resource_group_name
  resource_group_resource_id  = local.resource_group_id
  location                    = local.location
  firewall_vnet_address_space = var.firewall_vnet_address_space
  name_prefix                 = var.name_prefix
  #hub_virtual_network_resource_id = var.hub_virtual_network_resource_id
  hub_virtual_network_resource_id = module.deploy_hub_services_and_vnet.hub_vnet_resource_id
}

module "deploy_hub_services_and_vnet" {
  source = "../modules/deploy_hub_services_and_vnet"

  resource_group_name        = local.resource_group_name
  resource_group_resource_id = local.resource_group_id
  location                   = local.location
  address_space_hub_vnet     = var.address_space_hub_vnet
  address_space_bastion_vnet = var.address_space_bastion_vnet
  name_prefix                = var.name_prefix
  key_vault_resource_id      = module.deploy_network_infra.key_vault_resource_id
  firewall_lb_ip_address     = cidrhost(module.deploy_network_infra.trust_lb_subnet_address_prefix, 4)
  firewall_vnet_resource_id = module.deploy_network_infra.firewall_vnet_resource_id
}


data "azurerm_subscription" "current" {}

data "azapi_resource_action" "plans" {
  method                 = "GET"
  resource_id            = "${data.azurerm_subscription.current.id}/providers/Microsoft.MarketplaceOrdering/offerTypes/virtualmachine/publishers/paloaltonetworks/offers/vmseries-flex/plans/byol/agreements/current"
  type                   = "Microsoft.MarketplaceOrdering/offertypes/publishers/offers/plans/agreements@2021-01-01"
  response_export_values = ["*"]
}

module "deploy_firewall" {
  source = "../modules/deploy_firewall"

  resource_group_name            = local.resource_group_name
  resource_group_resource_id     = local.resource_group_id
  location                       = local.location
  name_prefix                    = var.name_prefix
  vm_sku                         = var.vm_sku
  image_version                  = var.palo_image_version
  key_vault_resource_id          = module.deploy_network_infra.key_vault_resource_id
  mgmt_subnet_resource_id        = module.deploy_network_infra.mgmt_subnet_resource_id
  trust_subnet_resource_id       = module.deploy_network_infra.trust_subnet_resource_id
  untrust_subnet_resource_id     = module.deploy_network_infra.untrust_subnet_resource_id
  trust_lb_subnet_resource_id    = module.deploy_network_infra.trust_lb_subnet_resource_id
  mgmt_subnet_address_prefix     = module.deploy_network_infra.mgmt_subnet_address_prefix
  trust_subnet_address_prefix    = module.deploy_network_infra.trust_subnet_address_prefix
  untrust_subnet_address_prefix  = module.deploy_network_infra.untrust_subnet_address_prefix
  trust_lb_subnet_address_prefix = module.deploy_network_infra.trust_lb_subnet_address_prefix
  admin_username                 = var.admin_username
  enable_marketplace_agreement   = data.azapi_resource_action.plans.output.properties.accepted == true ? false : true
  route_server_resource_id       = module.deploy_hub_services_and_vnet.route_server_resource_id
  firewall_asn                   = var.firewall_asn

  depends_on = [ module.deploy_network_infra, module.deploy_hub_services_and_vnet ]
}
