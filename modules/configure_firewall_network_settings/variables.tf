/*
variable "firewall_ip_address" {
  description = "IP address of the Palo Alto firewall"
  type        = string   
}

variable "firewall_username" {
  description = "Username for the Palo Alto firewall"
  type        = string  
}

variable "firewall_password_secret_name" {
  description = "Password for the Palo Alto firewall"
  type        = string
}

variable "firewall_password_key_vault_resource_id" {
  description = "Resource ID of the Key Vault containing the firewall password"
  type        = string  
}
*/
variable "trust_private_ip_address" {
  description = "Private IP address of the trust interface on the Palo Alto firewall"
  type        = string    
}

variable "untrust_private_ip_address" {
  description = "Private IP address of the trust interface on the Palo Alto firewall"
  type        = string    
}

variable "mgmt_private_ip_address" {
  description = "Private IP address of the management interface on the Palo Alto firewall"
  type        = string      
}

variable "ars_ip_address_1" {
  description = "IP address of the first Azure Route Server peer for the Palo Alto firewall"
  type        = string    
}

variable "ars_ip_address_2" {
  description = "IP address of the second Azure Route Server peer for the Palo Alto firewall"
  type        = string    
}

variable "egress_load_balancer_ip_address" {
  description = "IP address of the egress load balancer for the Palo Alto firewall"
  type        = string     
}

variable "trust_gateway_ip_address" {
  description = "IP address of the trust gateway for the Palo Alto firewall"
  type        = string  
}

variable "untrust_gateway_ip_address" {
  description = "IP address of the untrust gateway for the Palo Alto firewall"
  type        = string  
}

variable "prefix_size" {
  description = "Prefix size for the Palo Alto firewall interfaces"
  type        = number
}