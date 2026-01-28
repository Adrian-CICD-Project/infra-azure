resource "azurerm_automation_account" "aa" {
  name                = "${var.aks_name}-shutdown-aa"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Basic"
}

resource "azurerm_automation_runbook" "shutdown" {
  name                    = "${var.aks_name}-shutdown-runbook"
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.aa.name
  log_verbose             = true
  log_progress            = true
  runbook_type            = "PowerShell"

  content = <<EOF
param(
  [string] \$resourcegroupname,
  [string] \$clustername
)

Write-Output "Stopping AKS cluster \$clustername in RG \$resourcegroupname"

# TODO: tutaj docelowo:
# Connect-AzAccount -Identity
# Stop-AzAksCluster -ResourceGroupName \$resourcegroupname -Name \$clustername
EOF
}

resource "azurerm_automation_schedule" "daily" {
  name                    = "${var.aks_name}-shutdown-schedule"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.aa.name
  frequency               = "Day"
  interval                = 1
  timezone                = "UTC"
  start_time              = "${formatdate("YYYY-MM-DD", timestamp())}T${var.schedule_time}:00Z"
}

resource "azurerm_automation_job_schedule" "shutdown_job" {
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.aa.name
  schedule_name           = azurerm_automation_schedule.daily.name
  runbook_name            = azurerm_automation_runbook.shutdown.name

  parameters = {
    resourcegroupname = var.resource_group_name
    clustername       = var.aks_name
  }
}
