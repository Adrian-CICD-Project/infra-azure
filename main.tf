########################
# RESOURCE GROUP
########################
module "rg" {
  source   = "./modules/resource-group"
  rg_name  = var.rg_name
  location = var.location
}

########################
# NETWORK
########################
module "network" {
  source              = "./modules/network"
  resource_group_name = module.rg.rg_name
  location            = module.rg.location
  name_prefix         = var.name_prefix
}

########################
# ACR
########################
module "acr" {
  source              = "./modules/acr"
  acr_name            = var.acr_name
  resource_group_name = module.rg.rg_name
  location            = module.rg.location
}

########################
# AKS TEST
########################
module "aks_test" {
  source              = "./modules/aks"
  aks_name            = var.aks_test_name
  resource_group_name = module.rg.rg_name
  location            = module.rg.location

  node_vm_size   = var.node_vm_size
  node_count     = var.node_count
  max_pods       = 60  
  vnet_subnet_id = module.network.aks_subnet_id
  acr_id         = module.acr.acr_id
}

########################
# AKS PROD
########################
module "aks_prod" {
  source              = "./modules/aks"
  aks_name            = var.aks_prod_name
  resource_group_name = module.rg.rg_name
  location            = module.rg.location

  node_vm_size   = var.node_vm_size
  node_count     = var.node_count
  max_pods       = 60  
  vnet_subnet_id = module.network.aks_subnet_id
  acr_id         = module.acr.acr_id
}

########################
# ARGOCD – TEST
########################
#module "argocd_test" {
#  source = "./modules/argocd"
#
#  cluster_name         = module.aks_test.aks_name
#  resource_group_name  = module.rg.rg_name
#  location             = module.rg.location
#  app_of_apps_repo_url = "https://github.com/Adrian-CICD-Project/platform-apps.git"
#  app_of_apps_path     = "charts/app-of-apps"
#  static_ip_name       = "pip-argocd-test"
#
#  providers = {
#    helm = helm.test
#  }
#
#  depends_on = [module.aks_test]
#}


########################
# ARGOCD – PROD
########################
#module "argocd_prod" {
#  source = "./modules/argocd"
#
#  cluster_name         = module.aks_prod.aks_name
#  resource_group_name  = module.rg.rg_name
#  location             = module.rg.location
#  app_of_apps_repo_url = "https://github.com/Adrian-CICD-Project/platform-apps.git"
#  app_of_apps_path     = "charts/app-of-apps"
#  static_ip_name       = "pip-argocd-prod"
#
#  providers = {
#    helm = helm.prod
#  }
#
#  depends_on = [module.aks_prod]
#}




########################
# KEY VAULT
########################
module "key_vault" {
  source = "./modules/key-vault"

  key_vault_name      = "kv-devops-poc01-adrian"
  resource_group_name = module.rg.rg_name
  location            = module.rg.location

  aks_kubelet_identity_object_ids = [
    module.aks_test.kubelet_identity_object_id,
    module.aks_prod.kubelet_identity_object_id,
  ]
}

########################
# AUTO-SHUTDOWN – TEST
########################
module "auto_shutdown_test" {
  source = "./modules/auto-shutdown"

  resource_group_name = module.rg.rg_name
  aks_name            = module.aks_test.aks_name
  location            = module.rg.location
  schedule_time       = "22:00"
}

########################
# AUTO-SHUTDOWN – PROD
########################
module "auto_shutdown_prod" {
  source = "./modules/auto-shutdown"

  resource_group_name = module.rg.rg_name
  aks_name            = module.aks_prod.aks_name
  location            = module.rg.location
  schedule_time       = "22:00"
}
