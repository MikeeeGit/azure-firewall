# Synthetic existing network IDs. UKS matches the complete hub/spoke pack.
location             = "ukwest"
location_abbreviated = "ukw"
environment          = "hub"
subscription         = "hub"
resource_group_name  = "ukw-hub-vnet-rg-01"
availability_zones   = []
environment_tags     = { Environment = "hub", Region = "ukw" }
network = {
  virtual_network_id   = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/ukw-hub-vnet-rg-01/providers/Microsoft.Network/virtualNetworks/ukw-hub-vnet-01"
  firewall_subnet_id   = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/ukw-hub-vnet-rg-01/providers/Microsoft.Network/virtualNetworks/ukw-hub-vnet-01/subnets/AzureFirewallSubnet"
  firewall_subnet_cidr = "10.70.2.0/24"
}

# Independent standby firewall. No production allowlists are inherited.
aks_egress             = null
rule_collection_groups = {}
