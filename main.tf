locals {
  name     = var.override_name == null ? "${var.system_name}-${lower(var.environment)}-stapp" : var.override_name
  location = var.override_location == null ? var.resource_group.location : var.override_location
}

resource "azurerm_static_site" "static_site" {
  name                = local.name
  location            = local.location
  resource_group_name = var.resource_group.name

  sku_tier = var.sku_tier
  sku_size = var.sku_size

  dynamic "identity" {
    for_each = try(var.identity, null) == null ? [] : [1]

    content {
      type         = var.identity.type
      identity_ids = lower(var.identity.type) == "userassigned" ? local.managed_identities : null
    }
  }

  tags = var.tags
}
