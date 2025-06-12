# tflint-ignore: terraform_variable_separate, terraform_standard_module_structure
variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "resource_group_name" {
    description = "Name of the resource group"
    type        = string    
}

variable "resource_group_resource_id" {
    description = "Resource ID of the resource group"
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

variable "vm_sku" {
    description = "VM size to use for the firewall"
    type        = string  
}

variable "admin_username" {
    description = "Admin username for the firewall"
    type        = string  
    default     = "azureuser"
}

variable "image_version" {
  type = string
  default = "latest"
  description = "Image version for the firewall"
}

variable "key_vault_resource_id" {
    description = "Resource ID of the Key Vault"
    type        = string    
}

variable "mgmt_subnet_resource_id" {
    description = "Resource ID of the management subnet"
    type        = string    
}

variable "trust_subnet_resource_id" {
    description = "Resource ID of the trust subnet"
    type        = string     
}

variable "trust_lb_subnet_resource_id" {
    description = "Resource ID of the trust subnet"
    type        = string     
}

variable "untrust_subnet_resource_id" {
    description = "Resource ID of the untrust subnet"
    type        = string      
}

variable "mgmt_subnet_address_prefix" {
  description = "value of the management subnet address prefix"
  type        = string
}
variable "trust_subnet_address_prefix" {
  description = "value of the trust subnet address prefix"
  type        = string
}
variable "untrust_subnet_address_prefix" {
  description = "value of the untrust subnet address prefix"
  type        = string
}
variable "trust_lb_subnet_address_prefix" {
  description = "value of the untrust subnet address prefix"
  type        = string
}

variable "enable_marketplace_agreement" {
  type        = bool
  default     = false
  description = "Set to true if this is the first time you are deploying the ngfw Palo image into a subscription. This enables the marketplace agreement for the Palo Alto Networks VM-Series firewall. If you have already accepted the marketplace agreement, set this to false. Defaults to false."  
}

variable "palo_image_version" {
  type        = string
  default     = "11.2.5"
  description = "Version of the Palo Alto Networks VM-Series firewall image to use. Defaults to 11.2.5."  
}

variable "firewall_asn" {
  description = "Autonomous System Number (ASN) for the Palo Alto firewall"
  type        = number
  default     = 65001
}

variable "route_server_resource_id" {
  description = "Resource ID of the Azure Route Server"
  type        = string  
}