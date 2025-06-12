#get public IP address of vm1 and vm2 mgmt interface
locals {
  fw_vms = {
    vm1 = {
      name                        = "${var.name_prefix}-fw-vm1"
      zone                        = 1
      private_ip_address_mgmt     = cidrhost(local.subnets.management.address_prefixes[0], 4)
      private_ip_address_trust    = cidrhost(local.subnets.trust.address_prefixes[0], 4)
      private_ip_address_untrust  = cidrhost(local.subnets.untrust.address_prefixes[0], 4)
      private_ip_address_trust_lb = cidrhost(local.subnets.trust_lb.address_prefixes[0], 4)
      #private_ip_address_trust_lb = cidrhost(local.subnets.trust.address_prefixes[0], 4)
      gateway_ip_address_trust    = cidrhost(local.subnets.trust.address_prefixes[0], 1)
      gateway_ip_address_untrust  = cidrhost(local.subnets.untrust.address_prefixes[0], 1)
      password_secret_name        = "${var.name_prefix}-${var.name_prefix}-fw-vm1-${var.admin_username}-password"
    }
    vm2 = {
      name                        = "${var.name_prefix}-fw-vm2"
      zone                        = 2
      private_ip_address_mgmt     = cidrhost(local.subnets.management.address_prefixes[0], 5)
      private_ip_address_trust    = cidrhost(local.subnets.trust.address_prefixes[0], 5)
      private_ip_address_untrust  = cidrhost(local.subnets.untrust.address_prefixes[0], 5)
      private_ip_address_trust_lb = cidrhost(local.subnets.trust_lb.address_prefixes[0], 4)
      gateway_ip_address_trust    = cidrhost(local.subnets.trust.address_prefixes[0], 1)
      gateway_ip_address_untrust  = cidrhost(local.subnets.untrust.address_prefixes[0], 1)
      password_secret_name        = "${var.name_prefix}-${var.name_prefix}-fw-vm2-${var.admin_username}-password"
    }
  }

  subnets = {
    management = {
      name             = "${var.name_prefix}-mgmt-subnet"
      address_prefixes = [cidrsubnet(var.firewall_vnet_address_space, 3, 0)]
    }
    trust = {
      name             = "${var.name_prefix}-trust-subnet"
      address_prefixes = [cidrsubnet(var.firewall_vnet_address_space, 3, 1)]
    }
    untrust = {
      name             = "${var.name_prefix}-untrust-subnet"
      address_prefixes = [cidrsubnet(var.firewall_vnet_address_space, 3, 2)]
    }
    trust_lb = {
      name             = "${var.name_prefix}-trust-lb-subnet"
      address_prefixes = [cidrsubnet(var.firewall_vnet_address_space, 3, 3)]
    }
  }

  prefix_size = tostring(tonumber(split("/", var.firewall_vnet_address_space)[1]) + 3)
}


data "azurerm_public_ip" "fw1" {
  name                = "${var.name_prefix}-fw-vm1-mgmt-pip"
  resource_group_name = var.resource_group_name
}

data "azurerm_public_ip" "fw2" {
  name                = "${var.name_prefix}-fw-vm2-mgmt-pip"
  resource_group_name = var.resource_group_name
}

ephemeral "azurerm_key_vault_secret" "firewall_password" {
  for_each = local.fw_vms

  name         = each.value.password_secret_name
  key_vault_id = var.key_vault_resource_id
}

module "configure_firewall_network_settings_1" {
  source   = "../modules/configure_firewall_network_settings"
  for_each = { for k, v in local.fw_vms : k => v if k == "vm1" }

  providers = {
    panos = panos.firewall_1
  }

  trust_private_ip_address        = each.value.private_ip_address_trust
  untrust_private_ip_address      = each.value.private_ip_address_untrust
  mgmt_private_ip_address         = each.value.private_ip_address_mgmt
  ars_ip_address_1                = var.ars_ip_address_1
  ars_ip_address_2                = var.ars_ip_address_2
  egress_load_balancer_ip_address = each.value.private_ip_address_trust_lb
  trust_gateway_ip_address        = each.value.gateway_ip_address_trust
  untrust_gateway_ip_address      = each.value.gateway_ip_address_untrust
  prefix_size                     = local.prefix_size
}

module "configure_firewall_network_settings_2" {
  source   = "../modules/configure_firewall_network_settings"
  for_each = { for k, v in local.fw_vms : k => v if k == "vm2" }

  providers = {
    panos = panos.firewall_2
  }

  trust_private_ip_address        = each.value.private_ip_address_trust
  untrust_private_ip_address      = each.value.private_ip_address_untrust
  mgmt_private_ip_address         = each.value.private_ip_address_mgmt
  ars_ip_address_1                = var.ars_ip_address_1
  ars_ip_address_2                = var.ars_ip_address_2
  egress_load_balancer_ip_address = each.value.private_ip_address_trust_lb
  trust_gateway_ip_address        = each.value.gateway_ip_address_trust
  untrust_gateway_ip_address      = each.value.gateway_ip_address_untrust
  prefix_size                     = local.prefix_size
}

module "configure_initial_policy_1" {
  source   = "../modules/configure_firewall_base_policy"
  for_each = { for k, v in local.fw_vms : k => v if k == "vm1" }

  providers = {
    panos = panos.firewall_1
  }

  name_prefix          = var.name_prefix
  untrust_interface_ip = each.value.private_ip_address_untrust
  prefix_size = local.prefix_size
  depends_on           = [module.configure_firewall_network_settings_1]
}

module "configure_initial_policy_2" {
  source   = "../modules/configure_firewall_base_policy"
  for_each = { for k, v in local.fw_vms : k => v if k == "vm2" }

  providers = {
    panos = panos.firewall_2
  }

  name_prefix          = var.name_prefix
  untrust_interface_ip = each.value.private_ip_address_untrust
  prefix_size = local.prefix_size

  depends_on = [module.configure_firewall_network_settings_2]
}

