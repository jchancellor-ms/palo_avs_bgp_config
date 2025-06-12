locals {
  nsg_rules = {
    "Allow-All-In" = {
      name                       = "Allow-All-In"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_range     = "*"
      direction                  = "Inbound"
      priority                   = 110
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
    "Allow-443-In" = {
      name                       = "Allow-443-In"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_range     = "443"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
    "Allow-All-Out" = {
      name                       = "Allow-All-Out"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_range     = "*"
      direction                  = "Outbound"
      priority                   = 100
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
  }
}