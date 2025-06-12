#deploy VM's
locals {
  fw_vms = {
    vm1 = {
      name                       = "${var.name_prefix}-fw-vm1"
      zone                       = 1
      private_ip_address_mgmt    = cidrhost(var.mgmt_subnet_address_prefix, 4)
      private_ip_address_trust   = cidrhost(var.trust_subnet_address_prefix, 4)
      private_ip_address_untrust = cidrhost(var.untrust_subnet_address_prefix, 4)
    }
    vm2 = {
      name                       = "${var.name_prefix}-fw-vm2"
      zone                       = 2
      private_ip_address_mgmt    = cidrhost(var.mgmt_subnet_address_prefix, 5)
      private_ip_address_trust   = cidrhost(var.trust_subnet_address_prefix, 5)
      private_ip_address_untrust = cidrhost(var.untrust_subnet_address_prefix, 5)
    }
  }
}

resource "azurerm_marketplace_agreement" "palo" {
  #count = data.azapi_resource_action.plans.output.properties.accepted == true ? 0 : 1
  count = var.enable_marketplace_agreement ? 1 : 0

  publisher = "paloaltonetworks"
  offer     = "vmseries-flex"
  plan      = "byol"
}

resource "random_password" "admin_password" {
  length           = 22
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
  override_special = "!#$%&()*+,-./:;<=>?@[]^_{|}~"
  special          = true
}

module "testvm" {
  source   = "Azure/avm-res-compute-virtualmachine/azurerm"
  version  = "0.19.1"
  for_each = local.fw_vms

  enable_telemetry           = var.enable_telemetry
  location                   = var.location
  resource_group_name        = var.resource_group_name
  os_type                    = "Linux"
  name                       = each.value.name
  sku_size                   = var.vm_sku
  zone                       = each.value.zone
  encryption_at_host_enabled = false
  boot_diagnostics           = true

  account_credentials = {
    admin_credentials = {
      username = var.admin_username
      password = random_password.admin_password.result
      generate_admin_password_or_ssh_key = false
    }
    key_vault_configuration = {
      resource_id = var.key_vault_resource_id
      secret_configuration = {
        name = "${var.name_prefix}-${each.value.name}-${var.admin_username}-password"
      }
    }
    password_authentication_disabled = false
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference = {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = "byol"
    version   = var.image_version
  }

  plan = {
    name      = "byol"
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  network_interfaces = {
    management = {
      accelerated_networking_enabled = true
      ip_forwarding_enabled          = true
      is_primary                     = true
      name                           = "${each.value.name}-mgmt-nic"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${each.value.name}-mgmt-ipconfig1"
          private_ip_address_allocation = "Static"
          private_ip_address            = each.value.private_ip_address_mgmt
          private_ip_subnet_resource_id = var.mgmt_subnet_resource_id
          create_public_ip_address      = true
          public_ip_address_name        = "${each.value.name}-mgmt-pip"
        }
      }
    }
    untrust = {
      accelerated_networking_enabled = true
      ip_forwarding_enabled          = true
      name                           = "${each.value.name}-untrust-nic"
      ip_configurations = {
        ip_configuration_1 = {
          name = "${each.value.name}-untrust-ipconfig1"
          load_balancer_backend_pools = {
            backend_pool_1 = {
              load_balancer_backend_pool_resource_id = module.loadbalancer-ingress.azurerm_lb_backend_address_pool["backend_pool_1"].id
            }
          }
          private_ip_subnet_resource_id = var.untrust_subnet_resource_id
          private_ip_address_allocation = "Static"
          private_ip_address            = each.value.private_ip_address_untrust
          create_public_ip_address      = true
          public_ip_address_name        = "${each.value.name}-untrust-pip"
        }
      }
    }
    trust = {
      accelerated_networking_enabled = true
      ip_forwarding_enabled          = true
      name                           = "${each.value.name}-trust-nic"
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${each.value.name}-trust-ipconfig1"
          private_ip_subnet_resource_id = var.trust_subnet_resource_id
          private_ip_address_allocation = "Static"
          private_ip_address            = each.value.private_ip_address_trust
          load_balancer_backend_pools = {
            backend_pool_1 = {
              load_balancer_backend_pool_resource_id = module.loadbalancer-egress.azurerm_lb_backend_address_pool["backend_pool_1"].id
            }
          }
        }
      }
    }
  }
  depends_on = [azurerm_marketplace_agreement.palo]
}

#deploy ingress lb
module "loadbalancer-ingress" {
  source  = "Azure/avm-res-network-loadbalancer/azurerm"
  version = "0.2.2"

  name                = "${var.name_prefix}-ingress-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configurations = {
    frontend_configuration_1 = {
      name                            = "${var.name_prefix}-ingress-lb-frontend-ipconfig1"
      create_public_ip_address        = true
      public_ip_address_resource_name = "${var.name_prefix}-ingress-lb-frontend-ipconfig1-pip" #default public IP ingress
      zones                           = ["1", "2", "3"]
    }
  }

  backend_address_pools = {
    backend_pool_1 = {
      name = "${var.name_prefix}-ingress-lb-backendpool1"
    }
  }

  lb_rules = {
    allow_443_in = {
      name                             = "${var.name_prefix}-ingress-lb-443"
      frontend_ip_configuration_name   = "${var.name_prefix}-ingress-lb-frontend-ipconfig1"
      frontend_port                    = 443
      backend_port                     = 443
      load_distribution                = "Default"
      protocol                         = "Tcp"
      idle_timeout_in_minutes          = 4
      enable_floating_ip               = true
      backend_address_pool_object_names = ["backend_pool_1"]
      probe_object_name                = "health_probe"
    }
  }

  lb_probes = {
    health_probe = {
      name                            = "${var.name_prefix}-health-probe-443"
      protocol                        = "Tcp"
      port                            = 443
      interval_in_seconds             = 5
      number_of_probes_before_removal = 2
    }
  }
}

module "loadbalancer-egress" {
  source  = "Azure/avm-res-network-loadbalancer/azurerm"
  version = "0.2.2"

  name                = "${var.name_prefix}-egress-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

frontend_ip_configurations = {
    frontend_configuration_1 = {
      name                                   = "${var.name_prefix}-egress-lb-frontend-ipconfig1"
      frontend_private_ip_address            = cidrhost(var.trust_lb_subnet_address_prefix, 4)
      frontend_private_ip_address_allocation = "Static"
      frontend_private_ip_subnet_resource_id = var.trust_lb_subnet_resource_id
    }
  }

  backend_address_pools = {
    backend_pool_1 = {
      name = "${var.name_prefix}-ingress-lb-backendpool1"
    }
  }

  lb_rules = {
    allow_all_out = {
      name                             = "${var.name_prefix}-egress-lb-outbound-allow-all"
      frontend_ip_configuration_name   = "${var.name_prefix}-egress-lb-frontend-ipconfig1"
      frontend_port                    = 0
      backend_port                     = 0
      load_distribution                = "Default"
      protocol                         = "All"
      idle_timeout_in_minutes          = 4
      enable_floating_ip               = true
      backend_address_pool_object_names = ["backend_pool_1"]
      probe_object_name                = "health_probe"
    }
  }

  lb_probes = {
    health_probe = {
      name                            = "${var.name_prefix}-health-probe-443"
      protocol                        = "Tcp"
      port                            = 443
      interval_in_seconds             = 5
      number_of_probes_before_removal = 2
    }
  }
}

#peer to azure route server
resource "azurerm_virtual_hub_bgp_connection" "this" {
  for_each = local.fw_vms

  name           = "${each.value.name}-bgp-peer"
  peer_asn       = var.firewall_asn
  peer_ip        = local.fw_vms[each.key].private_ip_address_trust
  virtual_hub_id = var.route_server_resource_id
}