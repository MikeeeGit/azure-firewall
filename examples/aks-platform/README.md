# Envoy image and CSI certificate egress

Use this explicit additional layer when the private AKS nodes use the full Gateway API sample and pull the pinned Envoy images directly from Docker Hub. The base AKS/ACR policy does not implicitly authorize third-party registries or the application's Key Vault.

The child group at priority 300 permits only HTTPS443:

| Source | Destination | Purpose |
|---|---|---|
| Four published PPRD/PRD AKS node CIDRs | auth.docker.io, registry-1.docker.io, production.cloudfront.docker.com | Registry authentication, manifests and image layers |
| PPRD's two AKS node CIDRs | example-platform-app.vault.azure.net | The sample CSI certificate's exact vault endpoint |

The inherited base policy already permits the configured Entra authentication endpoint. The vault must separately permit this network path and the dedicated workload identity. For a private-endpoint vault, configure the correct private endpoint, DNS and routes instead of assuming this public-endpoint rule creates connectivity. PRD must use its own reviewed vault rule; it does not receive access to the PPRD vault here.

## Use this profile with saved-plan delivery

The local `tf_setup`/`tf_plan` helpers and authenticated component pipelines read **only** `config/global.tfvars`, followed by `config/<region>/<environment>/<environment>.tfvars`. They do not discover example files or accept `TF_CLI_ARGS`/`TF_VAR_*` overrides. The three-file command below is a credential-free validation composition.

For an actual private deployment, merge this profile's complete `rule_collection_groups` map into the private hub target tfvars before running the normal helper or pipeline. Preserve unrelated approved groups and priorities, replace the existing assignment rather than duplicating it, and replace synthetic destinations. Terraform replaces map-valued inputs; it does not recursively merge separate tfvars maps. Review the saved plan for the intended priority-300 group and exact registry/vault substitutions.

~~~bash
terraform test -test-directory=tests/platform-egress   -var-file=config/global.tfvars   -var-file=config/uks/hub/hub.tfvars   -var-file=examples/aks-platform/egress.tfvars
~~~

The test uses mocked providers and makes no Azure changes. Merge the layer into the private firewall target as described above before installing the controller or mounting its certificate.

This file replaces the entire rule_collection_groups map. Merge any existing custom or cross-spoke groups into a single reviewed private map; stacking two map-valued tfvars files does not merge them. Existing base groups and priorities are unchanged.

Docker's [official network allowlist](https://docs.docker.com/desktop/setup/allow-list/) identifies registry/authentication/CDN hosts. On 17 September 2026 the pinned Envoy Gateway1.9.1 and Envoy Proxy1.39.1 linux/amd64 layer requests both redirected to production.cloudfront.docker.com. This is a checked dependency for those inputs, not a promise that every future Docker Hub pull uses the same CDN. Review firewall logs and test actual image pulls after upgrades. A registry login or successful manifest request alone does not prove layer download.

An alternative is to mirror/import the reviewed controller and proxy images into your ACR, verify the resulting immutable digests, and update both the control-plane and proxy/shutdown-manager references in the platform values. That avoids direct Docker Hub access from nodes. Chart/CRD downloads and Trivy databases happen on CI runners; runner egress requires its own source-scoped policy and is not granted by this node-only overlay.

Key Vault authentication and object access use distinct endpoints; see [Microsoft Key Vault firewall guidance](https://learn.microsoft.com/en-us/azure/key-vault/general/access-behind-firewall). Validate real image pulls, CSI mounts, secret synchronization and certificate rotation in both selected clusters before traffic cutover.
