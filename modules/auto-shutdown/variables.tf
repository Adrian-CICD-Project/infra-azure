variable "resource_group_name" {
  type        = string
  description = "Resource group for the automation account"
}

variable "aks_name" {
  type        = string
  description = "Name of the AKS cluster to shutdown"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "schedule_time" {
  type        = string
  description = "Time in HH:MM (UTC) for shutdown schedule"
}
