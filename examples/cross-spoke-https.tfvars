# Optional additional var file for the UKS hub scenario. This REPLACES the
# rule_collection_groups map; merge existing custom groups before using it.
# Routes must be reciprocal through the same firewall and NSGs must allow them.
rule_collection_groups = {
  cross-spoke-https = {
    policy   = "child"
    priority = 200
    network_rule_collections = [{
      name     = "explicit-aks-https"
      priority = 100
      action   = "Allow"
      rules = [
        {
          name                  = "pprd-to-prd"
          protocols             = ["TCP"]
          source_addresses      = ["10.81.0.0/22", "10.81.4.0/22"]
          destination_addresses = ["10.82.0.0/22", "10.82.4.0/22"]
          destination_ports     = ["443"]
        },
        {
          name                  = "prd-to-pprd"
          protocols             = ["TCP"]
          source_addresses      = ["10.82.0.0/22", "10.82.4.0/22"]
          destination_addresses = ["10.81.0.0/22", "10.81.4.0/22"]
          destination_ports     = ["443"]
        }
      ]
    }]
  }
}
