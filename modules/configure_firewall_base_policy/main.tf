locals {
  location = {
    vsys = {
      name     = "vsys1"
      location = "localhost.localdomain"
    }
  }

  outbound_snat = {
    name                  = "${var.name_prefix}-outbound-snat"
    destination_addresses = ["any"]
    destination_zone      = ["untrust"]
    service               = "any"
    source_addresses      = ["any"]
    source_zones = ["trust"]
    source_translation = {
      dynamic_ip_and_port = {
        interface_address = {
          interface   = var.untrust_interface_eth
          #floating_ip = null
          ip          = "${var.untrust_interface_ip}/${var.prefix_size}" 
        }
      }
    }
  }

  allow_trust_to_any = {
    name                  = "${var.name_prefix}-allow-trust-to-any"
    destination_addresses = ["any"]
    destination_zones     = ["any"]
    services              = ["any"]
    source_addresses      = ["any"]
    source_zones          = ["trust"]
    applications          = ["any"]
  }

  allow_health_probes = {
    name                  = "${var.name_prefix}-allow-health-probes"
    destination_addresses = ["any"]
    destination_zones     = ["any"]
    services              = ["any"]
    source_addresses      = ["168.63.129.16/32"]
    source_zones          = ["any"]
    applications          = ["any"]
  }
}

resource "panos_nat_policy_rules" "inbound_pub_ip_rules" {
  location = local.location
  rules    = [local.outbound_snat]
  position = {
    where = "last"
  }
}

resource "panos_security_policy_rules" "allow_trust_to_any" {
  location = local.location
  rules    = [local.allow_trust_to_any]
  position = {
    where = "first"
  }
}

resource "panos_security_policy_rules" "allow_health_probes" {
  location = local.location
  rules    = [local.allow_health_probes]
  position = {
    where = "first"
  }
}