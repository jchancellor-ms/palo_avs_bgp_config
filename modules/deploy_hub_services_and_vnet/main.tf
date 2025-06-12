locals {
  resource_group_name_prod_hub  = "rg-${var.name_prefix}-hub-${var.location}"
  vnet_name_hub            = "vnet-${var.name_prefix}-hub-${var.location}"
  vnet_name_bastion        = "vnet-${var.name_prefix}-bastion-${var.location}"
  expressroute_gateway_name_hub = "vgw-${var.name_prefix}-hub-${var.location}"
  jump_vm_name                  = "${var.name_prefix}-jumpvm"
  bastion_name                  = "bastion-${var.name_prefix}-hub-${var.location}"
  bastion_pip_name              = "bastion-${var.name_prefix}-hub-${var.location}-pip"
  route_table_name              = "${var.name_prefix}-bastion-route-table"

  subnets = {
    GatewaySubnet = {
      name             = "GatewaySubnet"
      address_prefixes = [cidrsubnet(var.address_space_hub_vnet, 3, 0)]
    }
    RouteServerSubnet = {
      name             = "RouteServerSubnet"
      address_prefixes = [cidrsubnet(var.address_space_hub_vnet, 3, 1)]
    }
  }

  subnets_bastion = {
    AzureBastionSubnet = {
      name             = "AzureBastionSubnet"
      address_prefixes = [cidrsubnet(var.address_space_bastion_vnet, 3, 0)]
    }
    jumpvm = {
      name             = "${var.name_prefix}-jumpvm-subnet"
      address_prefixes = [cidrsubnet(var.address_space_bastion_vnet, 3, 1)]
      route_table = {
        id = azurerm_route_table.bastion.id
      }
    }
  }

}


module "hub_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.7.1"

  resource_group_name = var.resource_group_name
  address_space       = [var.address_space_hub_vnet]
  name                = local.vnet_name_hub
  location            = var.location

  subnets = local.subnets
}

resource "azurerm_route_table" "bastion" {
  location            = var.location
  name                = local.route_table_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_route" "default" {
  address_prefix      = "0.0.0.0/0"
  name                = "default"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_lb_ip_address
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.bastion.name
}



module "bastion_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.7.1"

  resource_group_name = var.resource_group_name
  address_space       = [var.address_space_bastion_vnet]
  name                = local.vnet_name_bastion
  location            = var.location

  subnets = local.subnets_bastion

    peerings = {
    peertohub = {
      name                                  = "${local.vnet_name_bastion}-to-hub"
      remote_virtual_network_resource_id    = var.firewall_vnet_resource_id
      allow_forwarded_traffic               = true
      allow_gateway_transit                 = false
      allow_virtual_network_access          = true
      do_not_verify_remote_gateways         = true
      enable_only_ipv6_peering              = false
      use_remote_gateways                   = false
      create_reverse_peering                = true
      reverse_name                          = "hub-to-${local.vnet_name_bastion}"
      reverse_allow_forwarded_traffic       = true
      reverse_allow_gateway_transit         = false
      reverse_allow_virtual_network_access  = true
      reverse_do_not_verify_remote_gateways = true
      reverse_enable_only_ipv6_peering      = false
      reverse_use_remote_gateways           = false
    }
  }
}

# expressRoute gateway
resource "azurerm_public_ip" "gateway_hub_pip" {
  allocation_method   = "Static"
  location            = var.location
  name                = "${local.expressroute_gateway_name_hub}-pip"
  resource_group_name = var.resource_group_name
  sku                 = "Standard" #required for an ultraperformance gateway
  zones               = ["1", "2", "3"]
}

resource "azurerm_virtual_network_gateway" "gateway_hub" {
  location            = var.location
  name                = local.expressroute_gateway_name_hub
  resource_group_name = var.resource_group_name
  sku                 = var.expressroute_gateway_sku_hub
  type                = "ExpressRoute"
  #fast_path_enabled   = true

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.gateway_hub_pip.id
    subnet_id                     = module.hub_vnet.subnets["GatewaySubnet"].resource_id
    name                          = "${local.expressroute_gateway_name_hub}-pip-ipconfig1"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "bastion_pip" {
  count = var.create_bastion ? 1 : 0

  allocation_method   = "Static"
  location            = var.location
  name                = local.bastion_pip_name
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_bastion_host" "bastion" {
  count = var.create_bastion ? 1 : 0

  location            = var.location
  name                = local.bastion_name
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  ip_configuration {
    name                 = "${local.bastion_name}-ipconf"
    public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
    subnet_id            = module.bastion_vnet.subnets["AzureBastionSubnet"].resource_id
  }
}


module "create_route_server" {
  source  = "Azure/avm-ptn-network-routeserver/azurerm"
  version = "0.1.5"

  resource_group_name             = var.resource_group_name
  resource_group_resource_id      = var.resource_group_resource_id
  location                        = var.location
  name                            = "${local.vnet_name_hub}-route-server"
  route_server_subnet_resource_id = module.hub_vnet.subnets["RouteServerSubnet"].resource_id
  enable_branch_to_branch         = true
  private_ip_allocation_method    = "Dynamic"
  routeserver_public_ip_config = {
    name = "${local.vnet_name_hub}-route-server-pip"
  }

  depends_on = [ azurerm_virtual_network_gateway.gateway_hub ]
}


#create the virtual machine
module "jumpvm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "=0.19.0"

  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  name                = local.jump_vm_name
  sku_size            = var.jump_vm_sku
  zone                = "1"

  account_credentials = {
    key_vault_configuration = {
      resource_id = var.key_vault_resource_id
    }
  }

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  managed_identities = {
    system_assigned = true
  }

  network_interfaces = {
    network_interface_1 = {
      name = "${local.jump_vm_name}-nic1"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${local.jump_vm_name}-nic1-ipconfig1"
          private_ip_subnet_resource_id = module.bastion_vnet.subnets["jumpvm"].resource_id
        }
      }
    }
  }
}
