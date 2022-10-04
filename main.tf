locals {
  # name = "${var.name}${var.environment}"
  name     = var.override_name == null ? var.name : var.override_name
  location = var.override_location == null ? var.resource_group.location : var.override_location
}

resource "azurerm_static_site" "static_site" {
  name                = local.name
  resource_group_name = var.resource_group.name

  # TODO: Error: failed creating Static Site: (Name "fm-ferdigmelding-test-stapp" / Resource Group "fm-ferdigmeldingen-test"): web.StaticSitesClient#CreateOrUpdateStaticSite: Failure sending request: StatusCode=400 -- Original Error: Code="LocationNotAvailableForResourceType" Message="The provided location 'norwayeast' is not available for resource type 'Microsoft.Web/staticSites'. List of available regions for the resource type is 'westus2,centralus,eastus2,westeurope,eastasia,eastasiastage'."
  # Workaround: Use westeurope as temporary solution while waiting for norwayeast being supported in the future.
  location = local.location

  sku_tier = var.sku_tier
  sku_size = var.sku_size

  identity {
    type = "SystemAssigned" # Possible values are SystemAssigned, UserAssigned and SystemAssigned, UserAssigned.
  }

  tags = var.tags
}
