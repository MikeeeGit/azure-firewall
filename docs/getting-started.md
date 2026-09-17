# Deployment and prerequisites

Use a new private consumer and backend key. Do not reuse an existing firewall's state or resource names without a separate migration review.

## Existing hub

Deploy networks and reciprocal peering first. Obtain hub outputs `vnet_id`, `subnet_ids["AzureFirewallSubnet"]`, `subnet_address_prefixes["AzureFirewallSubnet"]` and `vnet-rg`. Set `network` and `resource_group_name` from those actual values. The dedicated subnet must be named `AzureFirewallSubnet` and be `/26` or larger. Review Azure's subnet/NSG requirements; do not place a workload NSG or AKS route table on it.

UK South matches the complete `10.80/81/82` scenario. UK West is independent and matches the baseline `10.70.0.0/16` hub with firewall subnet `10.70.2.0/24`. It starts without an estate allowlist or AKS rules. Neither configuration creates automatic regional failover.

## Identity and backend

Replace synthetic tenant/subscription values in both `config/global.tfvars` and `delivery.azure.json`. Terraform rejects target inputs that disagree with the manifest. Register `Microsoft.Network` in the workload subscription before first deployment; automatic registration is disabled. Register `Microsoft.Insights` and destination providers when using diagnostics.

The deploy identity needs firewall/policy/public-IP permissions in the existing resource group and subnet join/read rights. Backend access is separate: the automation principal needs blob data permissions on private Entra-authenticated state storage. Resource Contributor does not grant state data access. No credential or access key belongs in tfvars.

Follow the [shared bootstrap guide](https://github.com/MikeeeGit/terraform-delivery-templates/blob/main/docs/azure/bootstrap.md). Use one reviewed template revision for private helpers and pipelines.

## Review and apply

For the maintained Envoy/CSI path, merge the [platform egress profile](../examples/aks-platform/README.md) into the private hub target first. Helpers load only the two documented tfvars files; they do not discover that example layer. Preserve other approved rule groups when merging the full map. The [sandbox runbook](https://github.com/MikeeeGit/terraform-delivery-templates/blob/main/docs/azure/sandbox-deployment.md) covers the dependency and cleanup gates.

With shared templates checked out alongside the private consumer:

```sh
source ../terraform-delivery-templates/scripts/azure/terraform-functions.sh
tf_setup azure-firewall hub uks
tf_init
tf_plan
# Review the saved plan, target and state before approving apply.
tf_apply
```

Use the actual consumer repository name if renamed. Select `hub ukw` for UK West. Helpers layer global tfvars followed by the selected regional/environment file and resolve the backend from `delivery.azure.json`.

A direct private workflow can use ignored `backend.local.hcl`, with a unique key, `use_azuread_auth=true` and environment-supplied authentication:

```sh
terraform init -backend-config=backend.local.hcl
terraform plan -var-file=config/global.tfvars -var-file=config/uks/hub/hub.tfvars -out=firewall.tfplan
terraform apply firewall.tfplan
terraform output firewall_private_ip
```

These commands describe a deliberate paid deployment; they were not run while preparing this repository. Public CI has no enabled deployment job or cloud identity.

After apply, follow [the network handoff](hub-spoke.md). Check actual firewall provisioning/IPs and real DNS/egress before AKS. Do not place test hosts inside the firewall subnet. Move dependent workloads/routes/DNS before destroying this state; removing a firewall still used as next hop or resolver causes an outage. This root does not own the existing resource group or subnet.
