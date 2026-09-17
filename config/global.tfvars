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
