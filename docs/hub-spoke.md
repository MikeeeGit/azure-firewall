# Network, DNS and AKS handoff

The UK South scenario uses hub FirewallSubnet `10.80.1.0/26`, PPRD AKS subnets `10.81.0.0/22` / `10.81.4.0/22`, and PRD AKS subnets `10.82.0.0/22` / `10.82.4.0/22`. This root alone owns the firewall, public IP and policies.

Deploy networks/peering, this firewall, DNS/routes, then AKS and gateway. After a successful apply, export `firewall_id`, `firewall_private_ip`, `firewall_policy_id` and public-IP outputs. Supply `firewall_id` to the network's route-only egress example; it reads the deployed firewall's actual private address from Azure. Stage route creation with `enable_aks_routes=false`, then explicitly enable associations after reviewing prerequisites. The later AKS UDR-readiness acknowledgement is an operator assertion, not a connectivity test.

Keep AKS route CSVs empty when the add-on owns associations. There must be one association owner per subnet and one firewall/policy owner. This root does not create routes, subnet associations, peerings, DNS zones or VNet DNS servers.

Set spoke VNet DNS lists to the actual firewall private IP in network state before creating AKS nodes. The proxy resolves through the hub: shared private AKS API zones, service private zones and gateway-owned backend alias zones need hub links. Verify UDP/TCP DNS from intended clients. AKS System DNS needs additional hub visibility/forwarding when using this custom resolver; the shared custom hub zone avoids that gap.

Attach AKS routes only after DNS and peering are ready. Inspect effective routes and required registry/platform connections from temporary private test NICs before acknowledging UDR readiness. Then test actual cluster bootstrap and image pulls. [AKS firewall guidance](https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic).

Peering is not transitive. Cross-spoke flows require reciprocal firewall routes, explicit policy and compatible NSGs/workload rules. The opt-in HTTPS example allows only TCP443 between the AKS ranges. Direct hub↔spoke and same-VNet traffic can follow more-specific system routes; an Internet default route does not inspect everything.

Application Gateway retains separate subnet routing/outbound requirements. Never attach AKS default routes to its subnet. Certificate preparation, public ingress, ingress controllers and internal service IPs belong to the gateway/AKS workflow.

No live routing, DNS or capacity was qualified by mocks. Review production SNAT needs before adopting the single-public-IP example. [Microsoft frontend capacity guidance](https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic#firewall-frontend-ip-requirements).

## Shared application registry

The UK South configuration explicitly allows HTTPS to `exampleplatformacr.azurecr.io`, `azurecr.io`, `*.blob.core.windows.net` and `login.microsoftonline.com` from the four AKS node CIDRs. Replace the synthetic registry login server alongside the network and application-delivery configuration. The login endpoint provides registry authentication; Entra token exchange uses the Microsoft sign-in endpoint. The AKS platform FQDN tag alone is not an application-registry policy.

Standard ACR uses Azure Blob storage endpoints for image layers. The domain-scoped Blob wildcard consequently permits other Azure Blob accounts over HTTPS from these node ranges; it is a deliberate example tradeoff, not registry-only isolation. Premium ACR can enable dedicated data endpoints such as `<registry>.<region>.data.azurecr.io`. If upgrading, discover and allow every actual regional endpoint before removing the Blob wildcard. [Microsoft registry firewall rules](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-firewall-rules).

After network/registry deployment, verify the actual login server and enabled endpoints with `az acr show --name <registry> --query loginServer -o tsv` and `az acr show-endpoints --name <registry>`. From the intended network, run `az acr check-health --name <registry> --yes` and an authenticated pull of the exact application image. A successful login alone does not prove image-layer access. Verify kubelet `AcrPull` role assignment separately, and test both PPRD and PRD paths before app delivery.

## DNS change readiness

When supplying custom `dns_servers`, map the complete recursive path before changing a live proxy. An upstream resolver must not send the same unresolved query back to this firewall, directly or through another resolver. A successful lookup through the currently serving path can hide a loop in a candidate upstream.

Test each configured upstream independently for both required private zones and external recursion, using UDP and TCP53, and repeat queries to expose inconsistent answers/timeouts. Check the resolver's forwarder and conditional-forwarder configuration as well as network reachability. The default empty upstream list uses Azure-provided DNS; the public example does not require domain controllers. With custom upstreams, those resolvers also need access or forwarding to the private zones: a hub VNet link by itself does not make every custom DNS server authoritative. There is no automatic Azure-DNS fallback when every configured upstream fails.

Prepare a reviewed rollback restoring the prior DNS settings and observe real workload name resolution/errors after a change. Account for positive and negative caches; changing the proxy does not refresh every client instantly. Configure VNet DNS before creating AKS nodes. Changes to existing nodes or other VM clients require a separate plan to refresh their effective DNS configuration safely; do not mix that operation into an application traffic cutover. [Azure Firewall DNS behavior](https://learn.microsoft.com/en-us/azure/firewall/dns-settings).
