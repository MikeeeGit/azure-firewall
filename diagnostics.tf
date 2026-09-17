resource "azurerm_monitor_diagnostic_setting" "firewall" {
  for_each                       = var.diagnostic_settings
  name                           = each.key
  target_resource_id             = azurerm_firewall.firewall.id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  storage_account_id             = each.value.storage_account_id
  eventhub_name                  = each.value.eventhub_name
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id
  log_analytics_destination_type = each.value.log_analytics_workspace_id == null ? null : each.value.log_analytics_destination_type
  dynamic "enabled_log" {
    for_each = each.value.enabled_log
    content {
      category       = enabled_log.value.category
      category_group = enabled_log.value.category_group
    }
  }
  dynamic "enabled_metric" {
    for_each = each.value.metrics
    content { category = enabled_metric.value }
  }
}
