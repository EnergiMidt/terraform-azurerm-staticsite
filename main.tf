locals {
  name     = var.override_name == null ? "${var.system_short_name}-${var.app_name}-${lower(var.environment)}-stapp" : var.override_name
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
      identity_ids = lower(var.identity.type) == "userassigned" ? var.identity.managed_identities : null
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

  count               = var.custom_domain_name != null && !var.dns_validation_with_txt_record ? 1 : 0
  name                = var.custom_domain_name.name
  zone_name           = var.custom_domain_name.zone_name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  record              = azurerm_static_site.static_site.default_host_name
}

resource "azurerm_dns_txt_record" "static_site_txt_record" {
  depends_on = [
    azurerm_dns_zone.tensio_zone
  ]

  count               = var.custom_domain_name != null && var.dns_validation_with_txt_record ? 1 : 0
  name                = "_dnsauth.${var.custom_domain_name.name}"
  zone_name           = var.custom_domain_name.zone_name
  resource_group_name = var.resource_group.name
  ttl                 = 300
  record {
    value = azurerm_static_site_custom_domain.static_site_custom_domain_txt[1].validation_token
  }
}

resource "azurerm_static_site_custom_domain" "static_site_custom_domain_cname" {
  depends_on = [
    azurerm_dns_cname_record.static_site_cname_record
  ]

  count           = var.custom_domain_name != null && !var.dns_validation_with_txt_record ? 1 : 0
  static_site_id  = azurerm_static_site.static_site.id
  domain_name     = "${var.custom_domain_name.name}.${var.custom_domain_name.zone_name}"
  validation_type = coalesce(var.custom_domain_name.validation_type, "cname-delegation")

  lifecycle {
    ignore_changes = [validation_token]
  }
}

resource "azurerm_static_site_custom_domain" "static_site_custom_domain_txt" {
  count           = var.custom_domain_name != null && var.dns_validation_with_txt_record ? 1 : 0
  static_site_id  = azurerm_static_site.static_site.id
  domain_name     = "${var.custom_domain_name.name}.${var.custom_domain_name.zone_name}"
  validation_type = "dns-txt-token"
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
        name       = "${azurerm_static_site.static_site.name}/appsettings"
        kind       = "string"
        properties = var.app_settings
      }
    ]
  }
}
