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

variable "firewall_vnet_address_space" {
    description = "VNet definition for the firewall"
    type        = string
}

variable "vm_sku" {
    description = "VM size to use for the firewall"
    type        = string  
    default     = "Standard_DS3_v2"  
}

variable "admin_username" {
    description = "Admin username for the firewall"
    type        = string  
    default     = "azureuser"
}
/*
variable "ars_ip_address_1" {
    description = "IP address for the first ARS"
    type        = string    
}

variable "ars_ip_address_2" {
    description = "IP address for the second ARS"
    type        = string      
}
*/
variable "palo_image_version" {
  type        = string
  default     = "11.2.5"
  description = "Version of the Palo Alto Networks VM-Series firewall image to use. Defaults to 11.2.5."  
}
/*
variable "enable_marketplace_agreement" {
  type        = bool
  default     = false
  description = "Set to true if this is the first time you are deploying the ngfw Palo image into a subscription. This enables the marketplace agreement for the Palo Alto Networks VM-Series firewall. If you have already accepted the marketplace agreement, set this to false. Defaults to false."  
}
*/
variable "create_resource_group" {
  type        = bool
  default     = true
  description = "Set to false if you want to use an existing resource group. Defaults to true."  
}

variable "firewall_asn" {
  description = "Autonomous System Number (ASN) for the Palo Alto firewall"
  type        = number
  default     = 65001
}

variable "address_space_hub_vnet" {
    description = "VNet definition for the firewall"
    type        = string
}

variable "address_space_bastion_vnet" {
    description = "VNet definition for the firewall"
    type        = string
}