# Repository guidance

This is Terraform deployment source. Keep changes focused and preserve resource addresses, rule priorities and ordered collections unless a migration is documented. Existing hub networks and routes are owned externally. Do not introduce a second firewall owner or change those repositories implicitly.

Use synthetic inputs and credential-free mocks. Never run cloud apply, change a backend, publish releases or expose private inputs merely to validate a code change. Do not commit `.terraform`, state, plans, credentials or private tfvars. Update provider locks intentionally; test the declared minimum provider in a disposable copy.

Follow [the test guide](docs/testing.md) and [source provenance](docs/source-provenance.md). Keep published repository names and cross-repository links consistent.
