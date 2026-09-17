output "firewall_id" { value = azurerm_firewall.firewall.id }
output "firewall_name" { value = azurerm_firewall.firewall.name }
output "firewall_private_ip" {
  description = "Actual allocated next-hop/DNS-proxy address. Network state owns its use in routes and VNet DNS."
  value       = one(azurerm_firewall.firewall.ip_configuration).private_ip_address
}
output "firewall_public_ip" { value = azurerm_public_ip.firewall.ip_address }
output "firewall_public_ip_id" { value = azurerm_public_ip.firewall.id }
output "base_firewall_policy_id" { value = azurerm_firewall_policy.base.id }
output "base_firewall_policy_name" { value = azurerm_firewall_policy.base.name }
output "firewall_policy_id" { value = azurerm_firewall_policy.child.id }
output "firewall_policy_name" { value = azurerm_firewall_policy.child.name }
output "firewall_subnet_id" { value = var.network.firewall_subnet_id }
output "virtual_network_id" { value = var.network.virtual_network_id }
output "resource_group_name" { value = var.resource_group_name }
output "deployment_summary" {
  value = {
    environment   = var.environment
    location      = var.location
    firewall_name = azurerm_firewall.firewall.name
    policy_name   = azurerm_firewall_policy.child.name
    sku_tier      = var.firewall_sku_tier
    zones         = var.availability_zones
    dns_proxy     = var.dns_proxy_enabled
    threat_intel  = var.threat_intelligence_mode
  }
}
