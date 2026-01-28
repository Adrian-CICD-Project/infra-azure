# Minimalny, bezproblemowy rozruch pod limity vCPU
variable "location" {
  type    = string
  default = "westeurope"
}
variable "rg_name" {
  type    = string
  default = "rg-devops-poc01"
}

# VM-ki z rodzin, które zwykle mają quota; jeśli trafisz na brak, zmień na "Standard_DS2_v2" lub "Standard_B4ms"
variable "node_vm_size" {
  type    = string
  default = "Standard_D8as_v5"
}

# Prosto: stała liczba węzłów (bez autoscalera)
variable "node_count" {
  type    = number
  default = 1
}

variable "aks_test_name" {
  type    = string
  default = "devops-poc01-test"
}

variable "aks_prod_name" {
  type    = string
  default = "devops-poc01-prod"
}

variable "acr_name" {
  type    = string
  default = "acrfordevopspoc01adrian"
}

variable "github_org_name" {
  description = "Adrian-CICD-Project"
  type        = string
}

# jeśli nie miałeś tagów, możesz dodać:
variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    project = "devops-final"
    owner   = "adrian-dmytryk"
  }
}
variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
}
