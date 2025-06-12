locals {
  location = {
    ngfw = {
      ngfw_dev = "localhost.localdomain"
    }
  }

  location_zone = {
    vsys = {
      name     = "vsys1"
      location = "localhost.localdomain"
    }
  }

  location_route_tables = {
    ngfw = {
      ngfw_device = "localhost.localdomain"
    }
  }

  trust_interface   = "ethernet1/1"
  untrust_interface = "ethernet1/2"
}

#configure management profiles
resource "panos_interface_management_profile" "mp_trust" {
  location = local.location

  name  = "mp-trust"
  https = true
  permitted_ips = [
    {
      name = "168.63.129.16/32"
    }
  ]
}

resource "panos_interface_management_profile" "mp_untrust" {
  location = local.location

  name  = "mp-untrust"
  https = true
  ssh   = true
  permitted_ips = [
    {
      name = "168.63.129.16/32"
    }
  ]
}

#Configure interfaces
resource "panos_ethernet_interface" "untrust" {
  location = local.location
  name     = local.untrust_interface
  layer3 = {
    interface_management_profile = panos_interface_management_profile.mp_untrust.name
    ips = [
      {
        name = "${var.untrust_private_ip_address}/${var.prefix_size}" 
      }
    ]
  }
}

resource "panos_ethernet_interface" "trust" {
  location = local.location
  name     = local.trust_interface
  layer3 = {
    interface_management_profile = panos_interface_management_profile.mp_trust.name
    ips = [
      {
        name = "${var.trust_private_ip_address}/${var.prefix_size}" 
      }
    ]
  }
}

#Configure virtual routers
resource "panos_virtual_router" "untrust-vr" {

  location = local.location
  name     = "untrust-vr"
  interfaces = [panos_ethernet_interface.untrust.name]
  #interfaces = [local.untrust_interface]

}

#Configure virtual routers
resource "panos_virtual_router" "trust-vr" {

  location = local.location
  name     = "trust-vr"
  interfaces = [panos_ethernet_interface.trust.name]
  #interfaces = [local.trust_interface]

  protocol = {
    bgp = {
      enable                     = true
      local_as                   = "65001"
      router_id                  = var.untrust_private_ip_address
      install_route              = true
      ecmp_multi_as              = true
      enforce_first_as           = true
      allow_redist_default_route = true

      peer_group = [
        {
          name                      = "azure-route-server-peer-group"
          aggregated_confed_as_path = true
          enable                    = true
          peer = [
            {
              name   = "ARS-1"
              enable = true
              peer_address = {
                ip = var.ars_ip_address_1
              }
              local_address = {
                ip = "${var.trust_private_ip_address}/${var.prefix_size}" 
                #interface = panos_ethernet_interface.trust.name
                interface = local.trust_interface 
              }
              peer_as = "65515"
            },
            {
              name   = "ARS-2"
              enable = true
              peer_address = {
                ip = var.ars_ip_address_2
              }
              local_address = {
                ip = "${var.trust_private_ip_address}/${var.prefix_size}" 
                #interface = panos_ethernet_interface.trust.name
                interface = local.trust_interface 
              }
              peer_as = "65515"
            }
          ]
        }
      ]

      policy = {
        export = {
          rules = [
            {
              name   = "export-default-route"
              enable = true
              match = {
                address_prefix = [
                  {
                    name  = "0.0.0.0/0"
                    exact = true
                  }
                ]
              }
              used_by = [
                "azure-route-server-peer-group"
              ]
              action = {
                allow = {
                  update = {
                    nexthop = var.egress_load_balancer_ip_address
                  }
                }
              }
            },
                        {
              name   = "export-10-8"
              enable = true
              match = {
                address_prefix = [
                  {
                    name  = "10.0.0.0/8"
                    exact = true
                  }
                ]
              }
              used_by = [
                "azure-route-server-peer-group"
              ]
              action = {
                allow = {
                  update = {
                    nexthop = var.egress_load_balancer_ip_address
                  }
                }
              }
            },
            {
              name   = "export-172-16-12"
              enable = true
              match = {
                address_prefix = [
                  {
                    name  = "172.16.0.0/12"
                    exact = true
                  }
                ]
              }
              used_by = [
                "azure-route-server-peer-group"
              ]
              action = {
                allow = {
                  update = {
                    nexthop = var.egress_load_balancer_ip_address
                  }
                }
              }
            },
                        {
              name   = "export-192-168-16"
              enable = true
              match = {
                address_prefix = [
                  {
                    name  = "192.168.0.0/16"
                    exact = true
                  }
                ]
              }
              used_by = [
                "azure-route-server-peer-group"
              ]
              action = {
                allow = {
                  update = {
                    nexthop = var.egress_load_balancer_ip_address
                  }
                }
              }
            }
          ]
        }
      }

      redist_rules = [
        {
          name                      = "0.0.0.0/0"
          address_family_identifier = "ipv4"
          enable                    = true
          set_origin                = "egp"
        },
        {
          name                      = "10.0.0.0/8"
          address_family_identifier = "ipv4"
          enable                    = true
          set_origin                = "egp"
        },
        {
          name                      = "172.16.0.0/12"
          address_family_identifier = "ipv4"
          enable                    = true
          set_origin                = "egp"
        },
        {
          name                      = "192.168.0.0/16"
          address_family_identifier = "ipv4"
          enable                    = true
          set_origin                = "egp"
        }
      ]
    }

    redist_profile = [{
      name     = "default-route"
      priority = 100
      action = {
        redist = {}
      }
      filter = {
        name        = "default-route"
        destination = ["0.0.0.0/0"]
        interface   = [local.trust_interface]
        type        = ["static"]
        nexthop     = [var.egress_load_balancer_ip_address]
      }
      }
    ]
  }
}


resource "panos_zone" "untrust-zone" {
  location = local.location_zone
  name     = "untrust"
  network = {
    enable_packet_buffer_protection = true
    #layer3                          = [local.untrust_interface]
    layer3 = [panos_ethernet_interface.untrust.name]
  }
}

resource "panos_zone" "trust-zone" {
  location = local.location_zone
  name     = "trust"
  network = {
    enable_packet_buffer_protection = true
    #layer3                          = [local.trust_interface]
    layer3 = [ panos_ethernet_interface.trust.name ]
  }
}


resource "panos_virtual_router_static_routes_ipv4" "trust" {
  location = local.location_route_tables

  virtual_router = panos_virtual_router.trust-vr.name
  static_routes = [
    {
      name        = "default"
      destination = "0.0.0.0/0"
      nexthop = {
        next_vr = panos_virtual_router.untrust-vr.name
      }
    },
    {
      name        = "route-for-healthprobe"
      destination = "168.63.129.16/32"
      interface   = panos_ethernet_interface.trust.name
      nexthop = {
        ip_address = var.trust_gateway_ip_address
      }
    },
    {
      name        = "route-for-10.x"
      destination = "10.0.0.0/8"
      interface   = panos_ethernet_interface.trust.name
      nexthop = {
        ip_address = var.trust_gateway_ip_address
      }
    },
    {
      name        = "route-for-172.16.x"
      destination = "172.16.0.0/12"
      interface   = panos_ethernet_interface.trust.name
      nexthop = {
        ip_address = var.trust_gateway_ip_address
      }
    },
    {
      name        = "route-for-192.168.x"
      destination = "192.168.0.0/16"
      interface   = panos_ethernet_interface.trust.name
      nexthop = {
        ip_address = var.trust_gateway_ip_address
      }
    },
    {
      name        = "route-for-ARS-1"
      destination = "${var.ars_ip_address_1}/32"
      interface   = panos_ethernet_interface.trust.name
      nexthop = {
        ip_address = var.trust_gateway_ip_address
      }
    },
    {
      name        = "route-for-ARS-2"
      destination = "${var.ars_ip_address_2}/32"
      interface   = panos_ethernet_interface.trust.name
      nexthop = {
        ip_address = var.trust_gateway_ip_address
      }
    }
  ]
}

resource "panos_virtual_router_static_routes_ipv4" "untrust" {
  location = local.location_route_tables

  virtual_router = panos_virtual_router.untrust-vr.name
  static_routes = [
    {
      name        = "default"
      destination = "0.0.0.0/0"
      interface   = panos_ethernet_interface.untrust.name
      nexthop = {
        ip_address = var.untrust_gateway_ip_address
      }
    },
    {
      name        = "route-for-10.x"
      destination = "10.0.0.0/8"
      nexthop = {
        next_vr = panos_virtual_router.trust-vr.name
      }
    },
    {
      name        = "route-for-172.16.x"
      destination = "172.16.0.0/12"
      nexthop = {
        next_vr = panos_virtual_router.trust-vr.name
      }
    },
    {
      name        = "route-for-192.168.x"
      destination = "192.168.0.0/16"
      nexthop = {
        next_vr = panos_virtual_router.trust-vr.name
      }
    },
    {
      name        = "route-for-healthprobe"
      destination = "168.63.129.16/32"
      interface   = panos_ethernet_interface.untrust.name
      nexthop = {
        ip_address = var.untrust_gateway_ip_address
      }
    }
  ]
}

