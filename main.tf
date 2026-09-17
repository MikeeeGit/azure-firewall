locals {
  label = "${var.location_abbreviated}-${var.environment}"
  tags  = merge(var.global_tags, var.environment_tags, { Environment = var.environment, Location = var.location, ManagedBy = "Terraform", Component = "AzureFirewall" })
}
resource "azurerm_public_ip" "firewall" {
  name                = "${local.label}-azfw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = local.tags
  depends_on          = [terraform_data.delivery_contract]
}
resource "azurerm_firewall_policy" "base" {
  name                = "${local.label}-azfw-base-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.firewall_sku_tier
  dns {
    proxy_enabled = var.dns_proxy_enabled
    servers       = var.dns_servers
  }
  private_ip_ranges        = length(var.private_ip_ranges) == 0 ? null : var.private_ip_ranges
  threat_intelligence_mode = var.threat_intelligence_mode
  dynamic "threat_intelligence_allowlist" {
    for_each = length(var.threat_intelligence_allowlist.ip_addresses) + length(var.threat_intelligence_allowlist.fqdns) == 0 ? [] : [var.threat_intelligence_allowlist]
    content {
      ip_addresses = threat_intelligence_allowlist.value.ip_addresses
      fqdns        = threat_intelligence_allowlist.value.fqdns
    }
  }
  tags       = local.tags
  depends_on = [terraform_data.delivery_contract]
}
resource "azurerm_firewall_policy" "child" {
  name                = "${local.label}-azfw-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  base_policy_id      = azurerm_firewall_policy.base.id
  sku                 = var.firewall_sku_tier
  dns {
    proxy_enabled = var.dns_proxy_enabled
    servers       = var.dns_servers
  }
  private_ip_ranges        = length(var.private_ip_ranges) == 0 ? null : var.private_ip_ranges
  threat_intelligence_mode = var.threat_intelligence_mode
  dynamic "threat_intelligence_allowlist" {
    for_each = length(var.threat_intelligence_allowlist.ip_addresses) + length(var.threat_intelligence_allowlist.fqdns) == 0 ? [] : [var.threat_intelligence_allowlist]
    content {
      ip_addresses = threat_intelligence_allowlist.value.ip_addresses
      fqdns        = threat_intelligence_allowlist.value.fqdns
    }
  }
  tags = local.tags
}
resource "azurerm_firewall" "firewall" {
  name                = "${local.label}-azfw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.child.id
  zones               = var.availability_zones
  ip_configuration {
    name                 = "${local.label}-azfw-ipconfig"
    subnet_id            = var.network.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
  tags = local.tags
}
