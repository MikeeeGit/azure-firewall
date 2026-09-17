# Optional layer after the UKS hub inputs. This REPLACES rule_collection_groups.
# Merge other private groups into this map before combining overlays.
rule_collection_groups = {
  aks-platform-services = {
    policy   = "child"
    priority = 300
    application_rule_collections = [{
      name     = "reviewed-platform-https"
      priority = 100
      action   = "Allow"
      rules = [
        {
          name              = "envoy-image-pulls"
          source_addresses  = ["10.81.0.0/22", "10.81.4.0/22", "10.82.0.0/22", "10.82.4.0/22"]
          destination_fqdns = ["auth.docker.io", "registry-1.docker.io", "production.cloudfront.docker.com"]
          protocols         = [{ type = "Https", port = 443 }]
        },
        {
          name              = "pprd-csi-vault"
          source_addresses  = ["10.81.0.0/22", "10.81.4.0/22"]
          destination_fqdns = ["example-platform-app.vault.azure.net"]
          protocols         = [{ type = "Https", port = 443 }]
        }
      ]
    }]
  }
}
