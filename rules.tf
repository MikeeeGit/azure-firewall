resource "azurerm_firewall_policy_rule_collection_group" "custom" {
  for_each           = var.rule_collection_groups
  name               = each.key
  priority           = each.value.priority
  firewall_policy_id = each.value.policy == "base" ? azurerm_firewall_policy.base.id : azurerm_firewall_policy.child.id
  dynamic "network_rule_collection" {
    for_each = each.value.network_rule_collections
    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action
      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.value.name
          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          destination_addresses = length(rule.value.destination_addresses) == 0 ? null : rule.value.destination_addresses
          destination_fqdns     = length(rule.value.destination_fqdns) == 0 ? null : rule.value.destination_fqdns
          destination_ports     = rule.value.destination_ports
        }
      }
    }
  }
  dynamic "application_rule_collection" {
    for_each = each.value.application_rule_collections
    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action
      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name              = rule.value.name
          source_addresses  = rule.value.source_addresses
          destination_fqdns = rule.value.destination_fqdns
          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }
}
resource "azurerm_firewall_policy_rule_collection_group" "aks" {
  count              = var.aks_egress == null ? 0 : 1
  name               = "aks-egress"
  priority           = 100
  firewall_policy_id = azurerm_firewall_policy.base.id
  application_rule_collection {
    name     = "aks-platform"
    priority = 200
    action   = "Allow"
    rule {
      name                  = "aks-required-endpoints"
      source_addresses      = var.aks_egress.source_addresses
      destination_fqdn_tags = ["AzureKubernetesService"]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
    dynamic "rule" {
      for_each = length(var.aks_egress.additional_registry_fqdns) == 0 ? [] : [1]
      content {
        name              = "additional-registries"
        source_addresses  = var.aks_egress.source_addresses
        destination_fqdns = var.aks_egress.additional_registry_fqdns
        protocols {
          type = "Https"
          port = 443
        }
      }
    }
  }
  dynamic "network_rule_collection" {
    for_each = var.aks_egress.allow_legacy_ntp ? [1] : []
    content {
      name     = "legacy-time"
      priority = 100
      action   = "Allow"
      rule {
        name              = "legacy-ntp"
        protocols         = ["UDP"]
        source_addresses  = var.aks_egress.source_addresses
        destination_fqdns = ["ntp.ubuntu.com"]
        destination_ports = ["123"]
      }
    }
  }
}
