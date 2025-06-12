variable "firewall_vnet_address_space" {
    description = "VNet definition for the firewall"
    type        = string
}

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

variable "hub_virtual_network_resource_id" {
    description = "Resource ID of the hub virtual network that will be used to peer the firewall vnet with the hub vnet"
    type        = string      
}

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