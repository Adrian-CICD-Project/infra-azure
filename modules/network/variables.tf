variable "resource_group_name" {
  type        = string
  description = "Resource group for the VNet"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for VNet / subnet names"
}
