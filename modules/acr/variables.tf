variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where ACR is created"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}
