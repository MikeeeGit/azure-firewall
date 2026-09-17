variable "rule_collection_groups" {
  description = "Named base/child policy groups. Ordered collection and rule lists retain caller order; priorities control Azure evaluation. No estate rules are implicit."
  type = map(object({
    policy   = optional(string, "child")
    priority = number
    network_rule_collections = optional(list(object({
      name     = string
      priority = number
      action   = string
      rules = list(object({
        name                  = string
        protocols             = list(string)
        source_addresses      = list(string)
        destination_addresses = optional(list(string), [])
        destination_fqdns     = optional(list(string), [])
        destination_ports     = list(string)
      }))
    })), [])
    application_rule_collections = optional(list(object({
      name     = string
      priority = number
      action   = string
      rules = list(object({
        name              = string
        source_addresses  = list(string)
        destination_fqdns = list(string)
        protocols         = list(object({ type = string, port = number }))
      }))
    })), [])
  }))
  default = {}
  validation {
    condition     = alltrue([for name, group in var.rule_collection_groups : can(regex("^[A-Za-z][A-Za-z0-9_-]{0,79}$", name)) && contains(["base", "child"], group.policy) && group.priority >= 100 && group.priority <= 65000 && floor(group.priority) == group.priority && length(group.network_rule_collections) + length(group.application_rule_collections) > 0])
    error_message = "Groups need valid stable names, base/child ownership, an integer priority 100-65000 and at least one nonempty collection."
  }
  validation {
    condition     = length(distinct([for group in var.rule_collection_groups : "${group.policy}/${group.priority}"])) == length(var.rule_collection_groups) && alltrue([for name, group in var.rule_collection_groups : var.aks_egress == null || group.policy != "base" || (name != "aks-egress" && group.priority != 100)])
    error_message = "Group priorities must be unique within each policy. Base name aks-egress and priority 100 are reserved when curated AKS egress is enabled."
  }
  validation {
    condition = alltrue([for group in var.rule_collection_groups :
      length(distinct(concat([for c in group.network_rule_collections : c.name], [for c in group.application_rule_collections : c.name]))) == length(group.network_rule_collections) + length(group.application_rule_collections) &&
      length(distinct(concat([for c in group.network_rule_collections : c.priority], [for c in group.application_rule_collections : c.priority]))) == length(group.network_rule_collections) + length(group.application_rule_collections) &&
      alltrue(concat([for c in group.network_rule_collections : contains(["Allow", "Deny"], c.action) && c.priority >= 100 && c.priority <= 65000 && floor(c.priority) == c.priority && length(c.rules) > 0 && length(distinct([for rule in c.rules : rule.name])) == length(c.rules)], [for c in group.application_rule_collections : contains(["Allow", "Deny"], c.action) && c.priority >= 100 && c.priority <= 65000 && floor(c.priority) == c.priority && length(c.rules) > 0 && length(distinct([for rule in c.rules : rule.name])) == length(c.rules)]))
    ])
    error_message = "Collections need unique names/priorities in their group, Allow/Deny, priorities 100-65000 and nonempty rules with unique names."
  }
  validation {
    condition = alltrue(flatten([for group in var.rule_collection_groups : [for collection in group.network_rule_collections : [for rule in collection.rules :
      length(rule.source_addresses) > 0 && length(rule.protocols) > 0 && alltrue([for protocol in rule.protocols : contains(["Any", "TCP", "UDP", "ICMP"], protocol)]) && length(rule.destination_ports) > 0 && (length(rule.destination_addresses) > 0 || length(rule.destination_fqdns) > 0) && (length(rule.destination_fqdns) == 0 || var.dns_proxy_enabled)
    ]]]))
    error_message = "Network rules need sources, supported protocols, destination ports and addresses/FQDNs. Network FQDN rules require DNS proxy."
  }
  validation {
    condition = alltrue(flatten([for group in var.rule_collection_groups : [for collection in group.application_rule_collections : [for rule in collection.rules :
      length(rule.source_addresses) > 0 && length(rule.destination_fqdns) > 0 && length(rule.protocols) > 0 && alltrue([for protocol in rule.protocols : contains(["Http", "Https", "Mssql"], protocol.type) && protocol.port >= 1 && protocol.port <= 65535 && floor(protocol.port) == protocol.port])
    ]]]))
    error_message = "Application rules need sources, FQDN destinations and valid Http/Https/Mssql ports."
  }
}
