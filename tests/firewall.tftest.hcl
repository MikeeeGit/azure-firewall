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
variables {
  # Public synthetic values; replace these and delivery.azure.json together.
  tenant_id = "00000000-0000-0000-0000-000000000001"
  subscription_id_map = {
    hub  = "00000000-0000-0000-0000-000000000002"
    pprd = "00000000-0000-0000-0000-000000000003"
    prd  = "00000000-0000-0000-0000-000000000004"
  }
  global_tags                   = { Owner = "platform-team@example.com", ManagedBy = "Terraform", Service = "firewall" }
  firewall_sku_tier             = "Standard"
  dns_proxy_enabled             = true
  dns_servers                   = []
  private_ip_ranges             = []
  threat_intelligence_mode      = "Alert"
  threat_intelligence_allowlist = {}
  diagnostic_settings           = {}
  # Synthetic existing network IDs. UKS matches the complete hub/spoke pack.
  location             = "uksouth"
  location_abbreviated = "uks"
  environment          = "hub"
  subscription         = "hub"
  resource_group_name  = "uks-hub-vnet-rg-01"
  availability_zones   = ["1", "2", "3"]
  environment_tags     = { Environment = "hub", Region = "uks" }
  network = {
    virtual_network_id   = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/uks-hub-vnet-rg-01/providers/Microsoft.Network/virtualNetworks/uks-hub-vnet-01"
    firewall_subnet_id   = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/uks-hub-vnet-rg-01/providers/Microsoft.Network/virtualNetworks/uks-hub-vnet-01/subnets/AzureFirewallSubnet"
    firewall_subnet_cidr = "10.80.1.0/26"
  }


}

run "default_ownership_and_policy_inheritance" {
  command = plan
  assert {
    condition     = azurerm_firewall.firewall.firewall_policy_id == azurerm_firewall_policy.child.id && azurerm_firewall_policy.child.base_policy_id == azurerm_firewall_policy.base.id && azurerm_firewall_policy.base.id != azurerm_firewall_policy.child.id && azurerm_firewall_policy.base.base_policy_id == null
    error_message = "The firewall must attach the child policy, which inherits the separately owned base policy."
  }
  assert {
    condition     = azurerm_firewall.firewall.sku_name == "AZFW_VNet" && azurerm_firewall.firewall.sku_tier == "Standard" && azurerm_public_ip.firewall.sku == "Standard" && one(azurerm_firewall.firewall.ip_configuration).subnet_id == var.network.firewall_subnet_id && one(azurerm_firewall.firewall.ip_configuration).public_ip_address_id == azurerm_public_ip.firewall.id
    error_message = "Use the existing dedicated firewall subnet and the created Standard public IP."
  }
  assert {
    condition     = azurerm_firewall_policy.base.dns[0].proxy_enabled && azurerm_firewall_policy.child.dns[0].proxy_enabled && length(azurerm_firewall_policy_rule_collection_group.custom) == 0 && length(azurerm_firewall_policy_rule_collection_group.aks) == 0 && length(azurerm_monitor_diagnostic_setting.firewall) == 0
    error_message = "DNS proxy is explicit, but no allowlists or diagnostics destinations should appear without caller configuration."
  }
  assert {
    condition     = output.firewall_private_ip == "10.80.1.4" && output.firewall_id == azurerm_firewall.firewall.id && output.firewall_public_ip == "192.0.2.10" && output.virtual_network_id == var.network.virtual_network_id && output.firewall_name == "uks-hub-azfw"
    error_message = "Outputs must expose actual computed firewall values and the existing network contract."
  }
}
run "scoped_aks_platform_and_explicit_extensions" {
  command = plan
  variables {
    aks_egress = {
      source_addresses          = ["10.81.0.0/22", "10.81.4.0/22", "10.82.0.0/22", "10.82.4.0/22"]
      additional_registry_fqdns = ["ghcr.io", "pkg-containers.githubusercontent.com"]
      allow_legacy_ntp          = true
    }
  }
  assert {
    condition     = azurerm_firewall_policy_rule_collection_group.aks[0].firewall_policy_id == azurerm_firewall_policy.base.id && azurerm_firewall_policy_rule_collection_group.aks[0].application_rule_collection[0].rule[0].name == "aks-required-endpoints" && toset(azurerm_firewall_policy_rule_collection_group.aks[0].application_rule_collection[0].rule[0].destination_fqdn_tags) == toset(["AzureKubernetesService"]) && alltrue([for rule in azurerm_firewall_policy_rule_collection_group.aks[0].application_rule_collection[0].rule : toset(rule.source_addresses) == toset(var.aks_egress.source_addresses)])
    error_message = "AKS egress must use the maintained platform tag and only the declared node sources in the base policy."
  }
  assert {
    condition     = toset(azurerm_firewall_policy_rule_collection_group.aks[0].application_rule_collection[0].rule[1].destination_fqdns) == toset(var.aks_egress.additional_registry_fqdns) && one(azurerm_firewall_policy_rule_collection_group.aks[0].network_rule_collection[0].rule[0].destination_ports) == "123" && one(azurerm_firewall_policy_rule_collection_group.aks[0].network_rule_collection[0].rule[0].protocols) == "UDP"
    error_message = "Extra registries and legacy NTP must follow explicit configuration, without unrelated public-control-plane ports."
  }
}
run "ordered_custom_base_and_child_rules" {
  command = plan
  variables {
    rule_collection_groups = {
      base-shared = {
        policy   = "base"
        priority = 300
        network_rule_collections = [
          { name = "later-priority-first-in-source", priority = 300, action = "Allow", rules = [
            { name = "second-service-first", protocols = ["TCP"], source_addresses = ["10.80.2.0/24"], destination_addresses = ["10.81.10.0/24"], destination_ports = ["443"] },
            { name = "first-service-second", protocols = ["TCP"], source_addresses = ["10.80.2.0/24"], destination_addresses = ["10.82.10.0/24"], destination_ports = ["443"] }
          ] },
          { name = "earlier-priority-second-in-source", priority = 100, action = "Deny", rules = [
            { name = "deny-other-private", protocols = ["Any"], source_addresses = ["10.80.2.0/24"], destination_addresses = ["10.0.0.0/8"], destination_ports = ["*"] }
          ] }
        ]
        application_rule_collections = [{ name = "approved-web", priority = 400, action = "Allow", rules = [
          { name = "example-web", source_addresses = ["10.80.2.0/24"], destination_fqdns = ["www.example.com"], protocols = [{ type = "Https", port = 443 }] }
        ] }]
      }
      child-environment = {
        policy   = "child"
        priority = 300
        network_rule_collections = [{ name = "explicit-dns", priority = 100, action = "Allow", rules = [
          { name = "resolver", protocols = ["UDP", "TCP"], source_addresses = ["10.81.0.0/22"], destination_addresses = ["10.80.2.4"], destination_ports = ["53"] }
        ] }]
      }
    }
  }
  assert {
    condition     = azurerm_firewall_policy_rule_collection_group.custom["base-shared"].firewall_policy_id == azurerm_firewall_policy.base.id && azurerm_firewall_policy_rule_collection_group.custom["child-environment"].firewall_policy_id == azurerm_firewall_policy.child.id && azurerm_firewall_policy_rule_collection_group.custom["base-shared"].network_rule_collection[0].name == "later-priority-first-in-source" && azurerm_firewall_policy_rule_collection_group.custom["base-shared"].network_rule_collection[0].rule[0].name == "second-service-first"
    error_message = "Keep each group on its selected policy and preserve caller collection/rule array order."
  }
}
run "explicit_diagnostics_dns_and_snat" {
  command = plan
  variables {
    dns_servers                   = ["10.80.2.4"]
    private_ip_ranges             = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "192.0.2.0/24"]
    threat_intelligence_mode      = "Deny"
    threat_intelligence_allowlist = { ip_addresses = ["203.0.113.10"], fqdns = ["example.com"] }
    diagnostic_settings = {
      operations = { log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-monitor-rg/providers/Microsoft.OperationalInsights/workspaces/example-monitor" }
    }
  }
  assert {
    condition     = toset(azurerm_firewall_policy.base.private_ip_ranges) == toset(var.private_ip_ranges) && toset(azurerm_firewall_policy.child.dns[0].servers) == toset(var.dns_servers) && azurerm_firewall_policy.base.threat_intelligence_mode == "Deny" && toset(azurerm_firewall_policy.child.threat_intelligence_allowlist[0].fqdns) == toset(["example.com"]) && azurerm_monitor_diagnostic_setting.firewall["operations"].target_resource_id == output.firewall_id
    error_message = "Declared DNS, SNAT, threat exceptions and diagnostics must be wired instead of silently ignored."
  }
}
run "reject_other_subscription_subnet" {
  command = plan
  variables {
    network = {
      virtual_network_id   = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/uks-pprd-vnet-rg-01/providers/Microsoft.Network/virtualNetworks/uks-pprd-vnet-01"
      firewall_subnet_id   = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/uks-pprd-vnet-rg-01/providers/Microsoft.Network/virtualNetworks/uks-pprd-vnet-01/subnets/AzureFirewallSubnet"
      firewall_subnet_cidr = "10.81.1.0/26"
    }
  }
  expect_failures = [var.network]
}
run "reject_tenant_delivery_mismatch" {
  command = plan
  variables { tenant_id = "00000000-0000-0000-0000-000000000009" }
  expect_failures = [terraform_data.delivery_contract]
}
run "reject_region_delivery_mismatch" {
  command = plan
  variables { location = "westeurope" }
  expect_failures = [terraform_data.delivery_contract]
}
run "reject_unsupported_basic_topology" {
  command = plan
  variables { firewall_sku_tier = "Basic" }
  expect_failures = [var.firewall_sku_tier]
}
run "reject_unrestricted_aks_source" {
  command = plan
  variables { aks_egress = { source_addresses = ["0.0.0.0/0"] } }
  expect_failures = [var.aks_egress]
}
run "reject_registry_wildcard" {
  command = plan
  variables { aks_egress = { source_addresses = ["10.81.0.0/22"], additional_registry_fqdns = ["*"] } }
  expect_failures = [var.aks_egress]
}
run "reject_aks_without_dns_proxy" {
  command = plan
  variables {
    dns_proxy_enabled = false
    aks_egress        = { source_addresses = ["10.81.0.0/22"] }
  }
  expect_failures = [var.aks_egress]
}
run "reject_empty_collection" {
  command = plan
  variables {
    rule_collection_groups = { empty = { priority = 200, network_rule_collections = [{ name = "empty", priority = 100, action = "Allow", rules = [] }] } }
  }
  expect_failures = [var.rule_collection_groups]
}
run "reject_duplicate_rule_priorities" {
  command = plan
  variables {
    rule_collection_groups = {
      duplicate = {
        priority = 200
        network_rule_collections = [
          { name = "first", priority = 100, action = "Allow", rules = [{ name = "https", protocols = ["TCP"], source_addresses = ["10.81.0.0/22"], destination_addresses = ["10.82.0.0/22"], destination_ports = ["443"] }] },
          { name = "second", priority = 100, action = "Allow", rules = [{ name = "https", protocols = ["TCP"], source_addresses = ["10.82.0.0/22"], destination_addresses = ["10.81.0.0/22"], destination_ports = ["443"] }] }
        ]
      }
    }
  }
  expect_failures = [var.rule_collection_groups]
}
run "reject_diagnostics_without_destination" {
  command = plan
  variables { diagnostic_settings = { invalid = {} } }
  expect_failures = [var.diagnostic_settings]
}
