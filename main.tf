data "azurerm_monitor_diagnostic_categories" "main" {
  resource_id = var.resource_id
}

locals {
  log_categories = (
    var.log_categories != null ?
    var.log_categories :
    data.azurerm_monitor_diagnostic_categories.main.logs
  )
  metric_categories = (
    var.metric_categories != null ?
    var.metric_categories :
    data.azurerm_monitor_diagnostic_categories.main.metrics
  )

  logs = {
    for category in local.log_categories : 
    category => {
      enabled        = var.enabled
      retention_days = var.retention_days
    }
  }

  metrics = {
    for metric in local.metric_categories : 
    metric => {
      enabled        = var.enabled
      retention_days = var.retention_days
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name               = var.name
  target_resource_id = var.resource_id

  storage_account_id             = var.storage_account_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id

  dynamic "log" {
    for_each = local.logs

    content {
      category = log.key
      enabled  = log.value.enabled

      retention_policy {
        enabled = log.value.retention_days != null ? true : false
        days    = log.value.retention_days
      }
    }
  }

  dynamic "metric" {
    for_each = local.metrics

    content {
      category = metric.key
      enabled  = metric.value.enabled

      retention_policy {
        enabled = metric.value.retention_days != null ? true : false
        days    = metric.value.retention_days
      }
    }
  }
}
