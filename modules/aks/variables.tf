variable "aks_name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "node_vm_size" {
  type        = string
  description = "Node VM size"
}

variable "node_count" {
  type        = number
  description = "Node count"
}

variable "vnet_subnet_id" {
  type        = string
  description = "Subnet ID for AKS node pool"
}

variable "acr_id" {
  type        = string
  description = "ACR ID for AcrPull role assignment"
}
variable "max_pods" {
  type    = number
  default = 60
}
