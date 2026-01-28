output "rg_name" {
  value = module.rg.rg_name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "aks_test_name" {
  value = module.aks_test.aks_name
}

output "aks_prod_name" {
  value = module.aks_prod.aks_name
}

output "aks_test_kube_config" {
  value     = module.aks_test.kube_config
  sensitive = true
}

output "aks_prod_kube_config" {
  value     = module.aks_prod.kube_config
  sensitive = true
}
