output "firewall_details" {
  description = "Details for the Palo Alto firewall"
  value = {
    firewall_1 = {
      mgmt_pip                        = module.testvm["vm1"].public_ips["management-ip_configuration_1"].ip_address
      username                        = var.admin_username
      password_secret_name            = "${module.testvm["vm1"].name}-${var.admin_username}-password"
      password_key_vault_resource_id  = var.key_vault_resource_id
      trust_private_ip_address        = local.fw_vms["vm1"].private_ip_address_trust
      untrust_private_ip_address      = local.fw_vms["vm1"].private_ip_address_untrust
      mgmt_private_ip_address         = local.fw_vms["vm1"].private_ip_address_mgmt
      egress_load_balancer_ip_address = cidrhost(var.trust_lb_subnet_address_prefix, 4)
    }
    firewall_2 = {
      mgmt_pip                        = module.testvm["vm2"].public_ips["management-ip_configuration_1"].ip_address
      username                        = var.admin_username
      password_secret_name            = "${module.testvm["vm2"].name}-${var.admin_username}-password"
      password_key_vault_resource_id  = var.key_vault_resource_id
      trust_private_ip_address        = local.fw_vms["vm2"].private_ip_address_trust
      untrust_private_ip_address      = local.fw_vms["vm2"].private_ip_address_untrust
      mgmt_private_ip_address         = local.fw_vms["vm2"].private_ip_address_mgmt
      egress_load_balancer_ip_address = cidrhost(var.trust_lb_subnet_address_prefix, 4)
    }
  }
}
