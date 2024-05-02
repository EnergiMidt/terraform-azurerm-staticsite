locals {
  name     = var.override_name == null ? "${var.system_short_name}-${var.app_name}-${lower(var.environment)}-stapp" : var.override_name
  location = var.override_location == null ? var.resource_group.location : var.override_location
}

resource "azurerm_static_web_app" "static_site" {
  name                = local.name
  location            = local.location
  resource_group_name = var.resource_group.name

  sku_tier = var.sku_tier
  sku_size = var.sku_size

  dynamic "identity" {
    for_each = try(var.identity, null) == null ? [] : [1]

    content {
      type         = var.identity.type
      identity_ids = lower(var.identity.type) == "userassigned" ? var.identity.identity_ids : null
    }
  }

  tags = var.tags
}

# Custom domain
resource "azurerm_dns_zone" "tensio_zone" {
  count               = var.custom_domain_name == null ? 0 : 1
  name                = var.custom_domain_name.zone_name
  resource_group_name = var.resource_group.name
}

resource "azurerm_dns_cname_record" "static_site_cname_record" {
  depends_on = [
    azurerm_dns_zone.tensio_zone
  ]

  count               = var.custom_domain_name == null ? 0 : 1
  name                = var.custom_domain_name.name
  zone_name           = var.custom_domain_name.zone_name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  record              = azurerm_static_web_app.static_site.default_host_name
}

resource "azurerm_static_web_app_custom_domain" "static_site_custom_domain" {
  depends_on = [
    azurerm_dns_cname_record.static_site_cname_record
  ]

  count             = var.custom_domain_name == null ? 0 : 1
  static_web_app_id = azurerm_static_web_app.static_site.id
  domain_name       = "${var.custom_domain_name.name}.${var.custom_domain_name.zone_name}"
  validation_type   = "cname-delegation"

  lifecycle {
    ignore_changes = [
      # azurerm acts weird when importing this and cannot reuse the existing value here.
      # Adding this to avoid destroying and recreating an existing resource if imported.
      validation_type
    ]
  }
}

# App settings for static app is not supported.
# https://github.com/hashicorp/terraform-provider-azurerm/issues/13451
resource "azurerm_resource_group_template_deployment" "static_site_appsettings" {
  deployment_mode     = "Incremental"
  name                = "static-site-appsettings"
  resource_group_name = var.resource_group.name

  template_content = jsonencode(local.appSettingsTemplate)
  parameters_content = jsonencode({
    for i, v in var.app_settings :
    "${i}" => {
      value = v
    }
  })
}

# Generate JSON file for ARM-template
locals {
  appSettingsTemplate = {
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters = ({
      for i, v in var.app_settings :
      "${i}" => {
        type = "string"
      }
    }),
    variables = {}
    resources = [
      {
        type       = "Microsoft.Web/staticSites/config"
        apiVersion = "2020-10-01"
        name       = "${azurerm_static_web_app.static_site.name}/appsettings"
        kind       = "string"
        properties = var.app_settings
      }
    ]
  }
}
