variable "admin_username" {
    description = "Admin username for the firewall"
    type        = string  
    default     = "azureuser"
}

variable "name_prefix" {
    description = "Prefix for the names of the resources"
    type        = string  
}

variable "resource_group_name" {
    description = "Name of the resource group"
    type        = string    
}

variable "key_vault_resource_id" {
    description = "Resource ID of the Key Vault"
    type        = string    
}

variable "firewall_vnet_address_space" {
    description = "VNet definition for the firewall"
    type        = string
}

variable "ars_ip_address_1" {
    description = "IP address for the first ARS"
    type        = string    
}

variable "ars_ip_address_2" {
    description = "IP address for the second ARS"
    type        = string      
}