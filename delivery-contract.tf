locals {
  delivery     = jsondecode(file("${path.root}/delivery.azure.json"))
  location_map = { uks = "uksouth", ukw = "ukwest" }
}
resource "terraform_data" "delivery_contract" {
  lifecycle {
    precondition {
      condition     = lower(var.tenant_id) == lower(local.delivery.tenant_id) && var.subscription_id_map == tomap(local.delivery.subscriptions)
      error_message = "Tenant and subscription aliases must exactly match delivery.azure.json."
    }
    precondition {
      condition     = try(local.delivery.environments[var.environment].subscription_alias == var.subscription, false) && contains(local.delivery.regions, var.location_abbreviated) && try(local.location_map[var.location_abbreviated] == var.location, false)
      error_message = "Environment, subscription alias, region abbreviation and Azure location must match the reviewed delivery target."
    }
  }
}
