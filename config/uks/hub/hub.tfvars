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

# Standard ACR sample: replace the login server when renaming the shared registry.
# Standard uses Azure Blob data endpoints; review this domain-scoped wildcard.
aks_egress = {
  source_addresses          = ["10.81.0.0/22", "10.81.4.0/22", "10.82.0.0/22", "10.82.4.0/22"]
  additional_registry_fqdns = ["exampleplatformacr.azurecr.io", "azurecr.io", "*.blob.core.windows.net", "login.microsoftonline.com"]
  allow_legacy_ntp          = false
}
rule_collection_groups = {}
