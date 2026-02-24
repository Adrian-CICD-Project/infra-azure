resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.aks_name

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "systempool"
    vm_size    = var.node_vm_size
    node_count = var.node_count
    vnet_subnet_id = var.vnet_subnet_id
    max_pods = var.max_pods
  }

  network_profile {
  network_plugin     = "azure"
  load_balancer_sku  = "standard"

  service_cidr       = "10.240.0.0/16"
  dns_service_ip     = "10.240.0.10"
}

}

# Role assignment: klaster może pullować z ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

# kubeconfig do konfiguracji providera helm/kubernetes
output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0]
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
