mock_provider "azurerm" {
  override_during = plan
  mock_resource "azurerm_public_ip" {
    defaults = {
      id         = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/uks-hub-vnet-rg-01/providers/Microsoft.Network/publicIPAddresses/uks-hub-azfw-pip"
      ip_address = "192.0.2.10"
    }
  }
  mock_resource "azurerm_firewall" {
    defaults = {
      id               = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/uks-hub-vnet-rg-01/providers/Microsoft.Network/azureFirewalls/uks-hub-azfw"
      ip_configuration = { private_ip_address = "10.80.1.4" }
    }
  }
}
override_resource {
  target          = azurerm_firewall_policy.base
  values          = { id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/uks-hub-vnet-rg-01/providers/Microsoft.Network/firewallPolicies/uks-hub-azfw-base-policy" }
  override_during = plan
}
override_resource {
  target          = azurerm_firewall_policy.child
  values          = { id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/uks-hub-vnet-rg-01/providers/Microsoft.Network/firewallPolicies/uks-hub-azfw-policy" }
  override_during = plan
}

run "reviewed_layered_configuration" {
  command = plan
  assert {
    condition     = azurerm_firewall.firewall.name == "${var.location_abbreviated}-${var.environment}-azfw" && azurerm_firewall.firewall.resource_group_name == var.resource_group_name && one(azurerm_firewall.firewall.ip_configuration).subnet_id == var.network.firewall_subnet_id && azurerm_firewall_policy.child.base_policy_id == azurerm_firewall_policy.base.id
    error_message = "Layered target files must preserve naming, actual network IDs and base-child inheritance."
  }
  assert {
    condition     = var.aks_egress == null ? length(azurerm_firewall_policy_rule_collection_group.aks) == 0 : toset(azurerm_firewall_policy_rule_collection_group.aks[0].application_rule_collection[0].rule[0].source_addresses) == toset(var.aks_egress.source_addresses)
    error_message = "Only explicitly configured targets receive scoped AKS egress."
  }
  assert {
    condition = var.aks_egress == null ? true : try(
      toset(azurerm_firewall_policy_rule_collection_group.aks[0].application_rule_collection[0].rule[1].destination_fqdns) == toset(["exampleplatformacr.azurecr.io", "azurecr.io", "*.blob.core.windows.net", "login.microsoftonline.com"]) &&
      one(azurerm_firewall_policy_rule_collection_group.aks[0].application_rule_collection[0].rule[1].protocols).type == "Https" &&
      one(azurerm_firewall_policy_rule_collection_group.aks[0].application_rule_collection[0].rule[1].protocols).port == 443,
      false
    )
    error_message = "The full Standard ACR example needs explicit login, storage and authentication egress over HTTPS."
  }
  assert {
    condition = !contains(keys(var.rule_collection_groups), "cross-spoke-https") ? true : try(
      azurerm_firewall_policy_rule_collection_group.custom["cross-spoke-https"].firewall_policy_id == azurerm_firewall_policy.child.id &&
      length(azurerm_firewall_policy_rule_collection_group.custom["cross-spoke-https"].network_rule_collection[0].rule) == 2 &&
      alltrue([for rule in azurerm_firewall_policy_rule_collection_group.custom["cross-spoke-https"].network_rule_collection[0].rule : toset(rule.protocols) == toset(["TCP"]) && toset(rule.destination_ports) == toset(["443"])]) &&
      toset(azurerm_firewall_policy_rule_collection_group.custom["cross-spoke-https"].network_rule_collection[0].rule[0].source_addresses) == toset(azurerm_firewall_policy_rule_collection_group.custom["cross-spoke-https"].network_rule_collection[0].rule[1].destination_addresses) &&
      toset(azurerm_firewall_policy_rule_collection_group.custom["cross-spoke-https"].network_rule_collection[0].rule[1].source_addresses) == toset(azurerm_firewall_policy_rule_collection_group.custom["cross-spoke-https"].network_rule_collection[0].rule[0].destination_addresses),
      false
    )
    error_message = "Cross-spoke HTTPS must be reciprocal, child-policy owned and limited to TCP443."
  }

}
