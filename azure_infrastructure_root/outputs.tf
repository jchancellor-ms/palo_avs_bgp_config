output "route_server_ips" {
  value = module.deploy_hub_services_and_vnet.route_server_ips
}

output "key_vault_resource_id" {
  value = module.deploy_network_infra.key_vault_resource_id
}

output "admin_username" {
  value = var.admin_username
}

output "name_prefix" {
  value = var.name_prefix  
}

output "firewall_vnet_address_space" {
  value = var.firewall_vnet_address_space
}

output "resource_group_name" {
  value = local.resource_group_name
}