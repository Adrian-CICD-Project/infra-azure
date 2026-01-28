resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

output "rg_name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}
