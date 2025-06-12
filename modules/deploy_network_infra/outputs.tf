output "mgmt_subnet_resource_id" {
  description = "Resource ID of the management subnet"
  value       = module.prod_firewall_vnet.subnets["management"].resource_id 
}

output "trust_subnet_resource_id" {
  description = "Resource ID of the trust subnet"
  value       = module.prod_firewall_vnet.subnets["trust"].resource_id
}

output "untrust_subnet_resource_id" {
  description = "Resource ID of the untrust subnet"
  value       = module.prod_firewall_vnet.subnets["untrust"].resource_id
}

output "trust_lb_subnet_resource_id" {
  description = "Resource ID of the trust load balancer subnet"
  value       = module.prod_firewall_vnet.subnets["trust_lb"].resource_id
}

output "mgmt_subnet_address_prefix" {
  description = "Address prefix of the management subnet"
  value       = module.prod_firewall_vnet.subnets["management"].resource.output.properties.addressPrefixes[0]
}

output "trust_subnet_address_prefix" {
  description = "Address prefix of the trust subnet"
  value       = module.prod_firewall_vnet.subnets["trust"].resource.output.properties.addressPrefixes[0]
}

output "untrust_subnet_address_prefix" {
  description = "Address prefix of the untrust subnet"
  value       = module.prod_firewall_vnet.subnets["untrust"].resource.output.properties.addressPrefixes[0]  
}

output "trust_lb_subnet_address_prefix" {
  description = "Address prefix of the trust load balancer subnet"
  value       = module.prod_firewall_vnet.subnets["trust_lb"].resource.output.properties.addressPrefixes[0]  
}

output "key_vault_resource_id" {
  description = "Resource ID of the Key Vault"
  value       = module.avm_res_keyvault_vault.resource_id
}

output "firewall_vnet_resource_id" {
  description = "Resource ID of the firewall virtual network"
  value       = module.prod_firewall_vnet.resource_id
}