variable "cluster_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "app_of_apps_repo_url" {
  type = string
}

variable "app_of_apps_path" {
  type = string
}

variable "static_ip_name" {
  type        = string
  default     = null
  description = "Optional public IP name for ArgoCD server LB"
}

resource "azurerm_public_ip" "argocd_ip" {
  count               = var.static_ip_name == null ? 0 : 1
  name                = var.static_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.6.0"

  namespace        = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]
}
