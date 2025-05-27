output "azurerm_static_site" {
  description = "The Azure App Service Static Site resource."
  value       = azurerm_static_web_app.static_site
}
