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

run "platform_images_and_certificate_path" {
  command = plan
  assert {
    condition = (
      azurerm_firewall_policy_rule_collection_group.custom["aks-platform-services"].firewall_policy_id == azurerm_firewall_policy.child.id &&
      azurerm_firewall_policy_rule_collection_group.custom["aks-platform-services"].priority == 300 &&
      azurerm_firewall_policy_rule_collection_group.aks[0].priority == 100
    )
    error_message = "The explicit platform overlay must preserve base policy ownership and existing AKS priority."
  }
  assert {
    condition = (
      length(azurerm_firewall_policy_rule_collection_group.custom["aks-platform-services"].network_rule_collection) == 0 &&
      azurerm_firewall_policy_rule_collection_group.custom["aks-platform-services"].application_rule_collection[0].action == "Allow" &&
      alltrue([for rule in azurerm_firewall_policy_rule_collection_group.custom["aks-platform-services"].application_rule_collection[0].rule :
        length(rule.protocols) == 1 && one(rule.protocols).type == "Https" && one(rule.protocols).port == 443
      ])
    )
    error_message = "Platform dependencies use HTTPS443 application rules, without a broad network allow."
  }
  assert {
    condition = (
      toset(azurerm_firewall_policy_rule_collection_group.custom["aks-platform-services"].application_rule_collection[0].rule[0].source_addresses) == toset(var.aks_egress.source_addresses) &&
      toset(azurerm_firewall_policy_rule_collection_group.custom["aks-platform-services"].application_rule_collection[0].rule[0].destination_fqdns) == toset(["auth.docker.io", "registry-1.docker.io", "production.cloudfront.docker.com"]) &&
      toset(azurerm_firewall_policy_rule_collection_group.custom["aks-platform-services"].application_rule_collection[0].rule[1].source_addresses) == toset(["10.81.0.0/22", "10.81.4.0/22"]) &&
      toset(azurerm_firewall_policy_rule_collection_group.custom["aks-platform-services"].application_rule_collection[0].rule[1].destination_fqdns) == toset(["example-platform-app.vault.azure.net"])
    )
    error_message = "Image hosts and the exact PPRD vault must retain their reviewed source boundaries."
  }
}
