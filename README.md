# Azure Firewall

Standalone public component derived from the reviewed `AZ-TF-azurefirewall` archive. The examples use synthetic inputs; live Azure deployment must be qualified in the chosen environment.

This root deploys a VNet-based Azure Firewall and Standard public IP into an existing hub, with a base Firewall Policy inherited by a child policy. It retains ordered network/application rules, DNS proxy and custom DNS, non-SNAT ranges, threat-intelligence settings, zones, tags and useful outputs. Regional configuration remains separate from shared configuration.

The UK South example integrates with the [network hub/spoke pack](https://github.com/MikeeeGit/azure-network-foundation/tree/main/examples/hub-spoke): hub `10.80.0.0/16`, PPRD `10.81.0.0/16`, PRD `10.82.0.0/16`. Optional AKS rules permit platform endpoints from the four dedicated node CIDRs. Cross-spoke HTTPS and additional registries require explicit configuration.

## Ownership

| Owner | Resources |
|---|---|
| This root | Public IP, firewall, base/child policies, rule groups, optional firewall diagnostics |
| Network foundation | Existing RG/VNet/FirewallSubnet, peering, private DNS zones/links, VNet DNS |
| Network route add-on | AKS route tables/associations consuming this firewall's actual IP |
| AKS/application repositories | Clusters, ingress controllers, services and gateway |

Creating a firewall does not route traffic through it. Consume `firewall_private_ip` in reviewed network DNS/UDRs after this deployment succeeds. The complete scenario has one firewall owner.

## Guides

- [Deployment and prerequisites](docs/getting-started.md)
- [Configuration and rule authoring](docs/configuration.md)
- [Network, DNS and AKS handoff](docs/hub-spoke.md)
- [Source provenance and migration](docs/source-provenance.md)
- [Credential-free tests](docs/testing.md)
- [Optional reciprocal HTTPS rules](examples/cross-spoke-https.tfvars)
- [Changelog](CHANGELOG.md)

Constraints: Terraform `>= 1.9, < 2`, AzureRM `>= 4.33, < 5`. Reproducible CLI/provider: 1.16.3 / 4.81.0. Public CI performs formatting, validation and mocks without cloud credentials. Trusted plan/apply belongs in a private consumer using the shared delivery framework.

Standard and Premium VNet firewalls are supported. Basic management-subnet designs, Virtual WAN, DNAT, TLS inspection and IDPS configuration are not implemented by this component or the active archived root. A Premium SKU alone does not enable advanced inspection.

Firewall and public IP resources incur charges. The single-IP example is a demonstration, not production SNAT sizing. Review current price, capacity, zones, monitoring and permitted traffic before deploying. Licensed under [Apache-2.0](LICENSE).

## CI change scope

Markdown-only edits use lightweight required GitHub checks and are excluded from automatic Azure validation builds. Changes to Terraform, application code, scripts, workflow definitions or executable examples still run full validation, including examples stored under docs/. Mixed changes also run full validation. Manual GitHub runs and unknown Git comparison ranges default to full validation.
