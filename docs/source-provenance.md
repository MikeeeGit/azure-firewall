# Source provenance and migration

This component was derived from the reviewed `AZ-TF-azurefirewall` root in the repository archive, reconciled against the 17 September 2026 update. Its root `AGENTS.md` was read before the active Terraform source. Originals and archive remain unchanged. No Git history, state, private tfvars, ARM exports, credentials or estate-specific allowlists were copied.

## Retained behavior

- VNet-based firewall and Standard static public IP in an existing hub resource group/subnet.
- Base Firewall Policy, inherited child policy, DNS proxy/custom resolvers, non-SNAT ranges, threat intelligence, zones and tags.
- Network and application rule groups, with explicit names/priorities and author-controlled collection/rule ordering.
- Regional shared/environment configuration and firewall, policy, public-IP, VNet/subnet/resource-group outputs.

The original active regional rules were network and application rules. Its root did not wire DNAT, TLS inspection or IDPS. These features have not been invented in the public copy.

## Explicit changes

Native AzureRM resources replace the archived Azure Verified Module calls. Generic typed ordered rule collections replace private regional address lists and partner allowlists. Copy only rules you have reviewed for your own environment; synthetic demonstration rules do not preserve a production estate's authorization policy.

Diagnostics and threat-intelligence allowlists were declared but not passed through the active archived root; they are now optional working inputs. Unused `diag_log_workspace`, telemetry and company metadata inputs were removed. The original accepted Basic/Virtual Hub values without the necessary management-subnet or Virtual Hub wiring. This version explicitly supports Standard/Premium VNet firewalls only.

The original shared environment naming is replaced by the explicit `hub` delivery target. The existing resource group and network IDs are inputs and are bound to the selected subscription. Shared manifest/variable tenant and subscription maps must match. The UK South scenario adds scoped AKS platform/registry egress. UK West remains independent without an imported estate allowlist; there is no automatic failover.

## State boundary

This is a fresh deployment interface, not an in-place state upgrade. Native resource addresses and naming differ from AVM-generated addresses. Existing infrastructure requires a separate inventory and reviewed import/state-move plan, including both policies and every rule group. Prove a no-unintended-change plan before adoption. Never point a new empty state at an existing firewall and assume Terraform will discover or safely migrate it.

Preserve policy hierarchy and Azure processing semantics during migration: base-policy rules run before child-policy rules, and network/application rule types have their own processing order. Input list order is retained for stable authoring; it does not override Azure's priority semantics. [Microsoft rule processing](https://learn.microsoft.com/en-us/azure/firewall/rule-processing).

## September source reconciliation

The updated root, variables and outputs are byte-identical to the earlier reviewed source. Regional rule data changed and one regional child policy gained an application-rule collection; the generic ordered collection interface already supports that shape. Private endpoint lists and operational incident details remain outside this public repository. Updated operational notes informed the DNS readiness guidance: assess the entire recursive forwarding path and each upstream resolver before changing a firewall proxy. No private DNS topology or allowlist is supplied as a default.
