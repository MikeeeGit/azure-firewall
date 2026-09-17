# Credential-free verification

Use Terraform 1.16.3 and the committed AzureRM 4.81.0 lock. These commands perform initialization without the backend and mocked plans without cloud authentication:

```sh
terraform init -backend=false -lockfile=readonly
terraform fmt -check -recursive
terraform validate
terraform test -test-directory=tests
terraform test -test-directory=tests/targets -var-file=config/global.tfvars -var-file=config/uks/hub/hub.tfvars
terraform test -test-directory=tests/targets -var-file=config/global.tfvars -var-file=config/ukw/hub/hub.tfvars
terraform test -test-directory=tests/targets -var-file=config/global.tfvars -var-file=config/uks/hub/hub.tfvars -var-file=examples/cross-spoke-https.tfvars
terraform test -test-directory=tests/platform-egress -var-file=config/global.tfvars -var-file=config/uks/hub/hub.tfvars -var-file=examples/aks-platform/egress.tfvars
```

Tests cover policy inheritance and ownership, AKS source restrictions, optional registry egress, ordered base/child rule wiring, diagnostics/DNS/SNAT settings, invalid target bindings, unsupported Basic SKU and malformed collections. Target tests exercise each published layered configuration and the optional cross-spoke overlay.

Minimum-provider checks use an isolated copy constrained to AzureRM 4.33.0, leaving the public 4.81.0 lock unchanged. Public GitHub and Azure Pipelines callers run only the shared credential-free validation template. Required GitHub checks are the reusable `validate` job under `Terraform root`, `Example uks/hub`, `Example ukw/hub` `Optional cross-spoke HTTPS` and `Optional AKS platform egress`; use the actual reported check names when setting branch protection. Azure Repos needs build-validation policies because YAML PR triggers do not enforce Azure Repos PR protection.

Mocks do not prove Azure authorization, provider registration, availability-zone support, successful resource creation, DNS resolution, traffic forwarding, application reachability or SNAT capacity. Qualify those in a private subscription after plan review. No cloud apply was used to prepare this component.
