# Configuration and rule authoring

Global tfvars contain shared tags, aliases and baseline settings. Regional hub files contain actual network IDs, zones and permitted traffic. Public values are synthetic. Rule groups default empty; UK South explicitly opts into curated AKS egress.

## Base and child rules

The firewall attaches the child policy, which inherits the base. Child allows cannot override inherited base denies. Azure evaluates rule types and priorities; source-file order alone is not a security boundary. Preserve group/collection/rule names and priorities. [Azure rule processing](https://learn.microsoft.com/en-us/azure/firewall/rule-processing).

`rule_collection_groups` maps stable Azure group names to `policy = "base" | "child"`, a group priority and ordered `network_rule_collections` / `application_rule_collections`. Collections have `name`, `priority`, `action = "Allow" | "Deny"` and ordered nonempty `rules`. Lists retain caller order, without automatic priority sorting. Group priorities are unique within each policy; collection priorities/names are unique within their group.

Network rules support protocols, source addresses, destination addresses/FQDNs and ports. Application rules support source addresses, destination FQDNs and Http/Https/Mssql protocol/port objects. These preserve the archive's active rule capabilities. No DNAT or inspection interface is added speculatively.

`aks_egress` reserves base group `aks-egress` and priority `100`. The AzureKubernetesService tag allows HTTP/HTTPS from only the selected node CIDRs. `additional_registry_fqdns` explicitly adds registry/auth/CDN HTTPS hosts; it does not discover image dependencies. `allow_legacy_ntp=false` suits modern private AKS; true adds only UDP123 to ntp.ubuntu.com. No TCP9000/UDP1194 exception is added. Check [current AKS outbound requirements](https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress).

The [cross-spoke HTTPS file](../examples/cross-spoke-https.tfvars) is opt-in. Adding it as a later var file REPLACES the entire `rule_collection_groups` map; merge existing groups first. Default configuration does not permit general PPRD↔PRD transit.

## DNS, SNAT and threat intelligence

DNS proxy defaults true; empty `dns_servers` uses Azure DNS. Link required private zones to the hub VNet. Custom upstream servers require reviewed forwarding and reachability. Network FQDN rules require proxy. VNet DNS changes remain network-owned.

Empty `private_ip_ranges` preserves Azure's default non-SNAT ranges. A supplied list replaces that behavior, so include every required range and review return routes. Use explicit IPv4 CIDRs; the provider rejects the portal's IANAPrivateRanges token.

Threat intelligence defaults Alert, as in the archive. Deny/Off and exceptions are explicit. Allowlist exceptions bypass threat classification; they do not create traffic-allow rules.

## Diagnostics and capacity

`diagnostic_settings={}` creates no log destination. Set an existing workspace, Storage or Event Hub resource ID. A workspace-only setting enables allLogs/AllMetrics by default:

```hcl
diagnostic_settings = {
  operations = {
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000002/resourceGroups/example-monitor-rg/providers/Microsoft.OperationalInsights/workspaces/example-monitor"
  }
}
```

Choose categories/metrics and destinations deliberately; logs incur ingestion/storage cost and need destination access. Firewall and public-IP zones match; use only target-region-supported zones (UK South example has three, UK West none).

One Standard public IP preserves the active archived topology. Production requires SNAT/throughput/cost review, suitable public-IP or supported NAT capacity, monitoring and recovery procedures. Mock success does not establish sizing.
