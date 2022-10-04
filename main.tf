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

  identity {
    type = "SystemAssigned" # (Required) Specifies the type of Managed Service Identity that should be configured on this resource. Possible values are `SystemAssigned`, `UserAssigned` and `SystemAssigned, UserAssigned` (to enable both).
  }

  tags = var.tags
}
