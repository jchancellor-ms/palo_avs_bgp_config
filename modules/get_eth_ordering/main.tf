locals {
  location = {
    ngfw = {
      ngfw_device = "localhost.localdomain"
    }
  }

  location_zone = {
    vsys = {
      name     = "vsys1"
      location = "localhost.localdomain"
    }
  }
}

data "panos_ethernet_interface" "untrust" {
  location = local.location

  name = "ethernet1/1"
}

data "panos_ethernet_interface" "trust" {
  location = local.location

  name = "ethernet1/2"
}

output "untrust_interface" {
  value = data.panos_ethernet_interface.untrust
}

output "trust_interface" {
  value = data.panos_ethernet_interface.trust
  
}