variable "key_vault_name" {
  type        = string
  description = "Name of the Azure Key Vault"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the Key Vault"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "aks_kubelet_identity_object_ids" {
  type        = list(string)
  description = "Object IDs of AKS kubelet managed identities that need access to Key Vault"
}
