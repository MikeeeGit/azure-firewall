# Design and migration compatibility

This component provides a VNet-based hub firewall with explicit policies, ordered rule collections and environment-specific delivery targets.

## Retained behavior

- VNet-based firewall and Standard static public IP in an existing hub resource group/subnet.
- Base Firewall Policy, inherited child policy, DNS proxy/custom resolvers, non-SNAT ranges, threat intelligence, zones and tags.
- Network and application rule groups, with explicit names/priorities and author-controlled collection/rule ordering.
- Regional shared/environment configuration and firewall, policy, public-IP, VNet/subnet/resource-group outputs.

Network and application rules are supported. DNAT, TLS inspection and IDPS configuration are outside the implemented interface.

## Explicit changes

Native AzureRM resources replace the archived Azure Verified Module calls. Generic typed ordered rule collections replace private regional address lists and partner allowlists. Copy only rules you have reviewed for your own environment; synthetic demonstration rules do not preserve a production estate's authorization policy.

Diagnostics and threat-intelligence allowlists are optional inputs. Standard/Premium VNet firewalls are supported; Basic management-subnet and Virtual Hub designs require a separate implementation.

Shared configuration uses the explicit `hub` delivery target. The existing resource group and network IDs are inputs and are bound to the selected subscription. Shared manifest/variable tenant and subscription maps must match. The UK South scenario adds scoped AKS platform/registry egress. UK West remains independent without an imported estate allowlist; there is no automatic failover.

## State boundary

This is a fresh deployment interface, not an in-place state upgrade. Native resource addresses and naming differ from AVM-generated addresses. Existing infrastructure requires a separate inventory and reviewed import/state-move plan, including both policies and every rule group. Prove a no-unintended-change plan before adoption. Never point a new empty state at an existing firewall and assume Terraform will discover or safely migrate it.

Preserve policy hierarchy and Azure processing semantics during migration: base-policy rules run before child-policy rules, and network/application rule types have their own processing order. Input list order is retained for stable authoring; it does not override Azure's priority semantics. [Microsoft rule processing](https://learn.microsoft.com/en-us/azure/firewall/rule-processing).

## DNS and rule review

Review each environment's rule collections and the entire recursive DNS forwarding path before deployment. Check every upstream resolver before changing a firewall proxy, and avoid forwarding loops. Synthetic example destinations must be replaced with the dependencies required by the target workloads.
