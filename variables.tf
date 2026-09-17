variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant, matching delivery.azure.json."
}
variable "subscription_id_map" {
  type        = map(string)
  description = "Explicit workload/backend subscription aliases, matching delivery.azure.json."
}
variable "subscription" {
  type = string
  validation {
    condition     = contains(keys(var.subscription_id_map), var.subscription)
    error_message = "Select a subscription alias present in subscription_id_map."
  }
}
variable "environment" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.environment))
    error_message = "Use a lowercase environment name of 2-12 letters/digits."
  }
}
variable "location" { type = string }
variable "location_abbreviated" { type = string }
variable "resource_group_name" {
  type        = string
  description = "Existing resource group in the workload subscription. This stack does not own its lifecycle."
}
variable "network" {
  type = object({
    virtual_network_id   = string
    firewall_subnet_id   = string
    firewall_subnet_cidr = string
  })
  description = "Actual existing network outputs. The subnet must be AzureFirewallSubnet and /26 or larger."
  validation {
    condition     = can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", var.network.virtual_network_id)) && lower(var.network.firewall_subnet_id) == "${lower(var.network.virtual_network_id)}/subnets/azurefirewallsubnet" && try(lower(split("/", var.network.virtual_network_id)[2]) == lower(var.subscription_id_map[var.subscription]), false)
    error_message = "Use an AzureFirewallSubnet ID beneath the declared VNet in the selected workload subscription."
  }
  validation {
    condition     = can(cidrnetmask(var.network.firewall_subnet_cidr)) && try(tonumber(split("/", var.network.firewall_subnet_cidr)[1]) <= 26, false)
    error_message = "AzureFirewallSubnet must be a valid IPv4 CIDR of /26 or larger."
  }
}
variable "firewall_sku_tier" {
  type        = string
  default     = "Standard"
  description = "The archived working VNet topology supports Standard or Premium. Premium inspection features require a separate explicit design."
  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "Use Standard or Premium; Basic management subnet and Virtual WAN Hub designs are not implemented."
  }
}
variable "availability_zones" {
  type    = list(string)
  default = []
  validation {
    condition     = length(distinct(var.availability_zones)) == length(var.availability_zones) && alltrue([for zone in var.availability_zones : contains(["1", "2", "3"], zone)])
    error_message = "Use unique region-supported zone strings 1, 2, 3, or [] for a non-zonal deployment."
  }
}
variable "dns_proxy_enabled" {
  type    = bool
  default = true
}
variable "dns_servers" {
  type        = list(string)
  default     = []
  description = "Upstream DNS server IPs. Empty uses Azure-provided DNS; required private zones must be linked to the firewall VNet."
  validation {
    condition     = alltrue([for ip in var.dns_servers : can(cidrnetmask("${ip}/32"))])
    error_message = "Custom DNS servers must be IPv4 addresses."
  }
}
variable "private_ip_ranges" {
  type        = list(string)
  default     = []
  description = "Optional override of the policy's non-SNAT ranges. Empty preserves Azure defaults; review before changing return routing."
  validation {
    condition     = alltrue([for cidr in var.private_ip_ranges : can(cidrnetmask(cidr))])
    error_message = "Use explicit IPv4 CIDRs. Empty keeps the Azure default non-SNAT ranges."
  }
}
variable "threat_intelligence_mode" {
  type    = string
  default = "Alert"
  validation {
    condition     = contains(["Alert", "Deny", "Off"], var.threat_intelligence_mode)
    error_message = "Threat intelligence mode must be Alert, Deny or Off."
  }
}
variable "threat_intelligence_allowlist" {
  type        = object({ ip_addresses = optional(list(string), []), fqdns = optional(list(string), []) })
  default     = {}
  description = "Explicit threat-intelligence exceptions, empty by default; these do not add allow rules."
}
variable "global_tags" {
  type    = map(string)
  default = {}
}
variable "environment_tags" {
  type    = map(string)
  default = {}
}
variable "aks_egress" {
  type = object({
    source_addresses          = list(string)
    additional_registry_fqdns = optional(list(string), [])
    allow_legacy_ntp          = optional(bool, false)
  })
  default     = null
  description = "Optional curated base-policy AKS egress. Four real node CIDRs are used by the hub/spoke example; extra registry/auth/CDN destinations are explicit."
  validation {
    condition     = var.aks_egress == null ? true : length(var.aks_egress.source_addresses) > 0 && alltrue([for cidr in var.aks_egress.source_addresses : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"])
    error_message = "AKS egress needs explicit IPv4 node subnet CIDRs; unrestricted sources are not accepted."
  }
  validation {
    condition     = var.aks_egress == null ? true : alltrue([for fqdn in var.aks_egress.additional_registry_fqdns : can(regex("^(\\*\\.)?[a-zA-Z0-9][a-zA-Z0-9.-]*\\.[a-zA-Z]{2,}$", fqdn))])
    error_message = "Extra registry destinations must be hostnames, optionally prefixed with *., without schemes, paths or unrestricted *."
  }
  validation {
    condition     = var.aks_egress == null ? true : var.dns_proxy_enabled
    error_message = "The curated AKS egress example requires DNS proxy so clients and firewall use a consistent resolver."
  }
}
variable "diagnostic_settings" {
  type = map(object({
    log_analytics_workspace_id     = optional(string)
    storage_account_id             = optional(string)
    eventhub_name                  = optional(string)
    eventhub_authorization_rule_id = optional(string)
    log_analytics_destination_type = optional(string, "Dedicated")
    enabled_log                    = optional(list(object({ category = optional(string), category_group = optional(string) })), [{ category_group = "allLogs" }])
    metrics                        = optional(list(string), ["AllMetrics"])
  }))
  default     = {}
  description = "Optional firewall diagnostics. Destinations must already exist; no diagnostics or log storage is created by default."
  validation {
    condition     = alltrue([for setting in var.diagnostic_settings : (setting.log_analytics_workspace_id != null || setting.storage_account_id != null || setting.eventhub_authorization_rule_id != null) && (setting.eventhub_name == null || setting.eventhub_authorization_rule_id != null) && alltrue([for log in setting.enabled_log : (log.category == null) != (log.category_group == null)])])
    error_message = "Each diagnostic setting needs a destination and logs must select exactly one category or category_group. Event Hub name requires its authorization-rule ID."
  }
}
