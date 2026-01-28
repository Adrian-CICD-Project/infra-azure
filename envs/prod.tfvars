######################################
# ENV PROD
######################################

# --- Lokalizacja ---
location = "westeurope"

# --- Nazwy zasobów ---
name_prefix   = "devops-poc01"
rg_name       = "rg-devops-poc01"
acr_name = "acrfordevopspoc01adrian"


# --- Nazwy klastrów ---
aks_test_name = "devops-poc01-test"
aks_prod_name = "devops-poc01-prod"

# --- AKS parametry ---
node_vm_size = "Standard_B4ms"
node_count   = 1

# --- GitHub ---
github_org_name = "devops-project-adrian-dmytryk"

# --- Tagi governance ---
tags = {
  project = "devops-final"
  env     = "prod"
  owner   = "adrian-dmytryk"
}
