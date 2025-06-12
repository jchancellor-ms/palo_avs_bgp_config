variable "name_prefix" {
  description = "value of the name prefix"
  type        = string
}

variable "untrust_interface_eth" {
  description = "Name of the untrust interface ethernet"
  type        = string
  default     = "ethernet1/2"  
}

variable "trust_interface_eth" {
  description = "Name of the trust interface ethernet"
  type        = string  
  default     = "ethernet1/1"    
}

variable "untrust_interface_ip" {
  description = "IP address for the untrust interface"
  type        = string  
}

variable "prefix_size" {
  description = "Prefix size for the Palo Alto firewall interfaces"
  type        = number
}