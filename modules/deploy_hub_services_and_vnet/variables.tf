variable "resource_group_name" {
    description = "Name of the resource group"
    type        = string    
}

variable "location" {
    description = "Location of the resource group"
    type        = string    
}

variable "name_prefix" {
    description = "Prefix for the names of the resources"
    type        = string  
}

variable "resource_group_resource_id" {
    description = "Resource ID of the resource group"
    type        = string    
}

variable "address_space_hub_vnet" {
    description = "VNet definition for the firewall"
    type        = string
}

variable "address_space_bastion_vnet" {
    description = "VNet definition for the firewall"
    type        = string
}

variable "key_vault_resource_id" {
    description = "Resource ID of the Key Vault"
    type        = string  
}

variable "jump_vm_sku" {
    description = "SKU for the jump VM"
    type        = string
    default     = "Standard_D2s_v5"  
}

variable "expressroute_gateway_sku_hub" {
    description = "SKU for the ExpressRoute gateway in the hub"
    type        = string
    default     = "ErGw1AZ"   
}

variable "create_bastion" {
    description = "Flag to create a Bastion host in the hub"
    type        = bool
    default     = true  
}

variable "firewall_lb_ip_address" {
    description = "IP address of the firewall load balancer"
    type        = string
}

variable "firewall_vnet_resource_id" {
    description = "Resource ID of the firewall VNet"
    type        = string      
}