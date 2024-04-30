output "dotnet_webapp_url" {
  value = azurerm_windows_web_app.app.default_hostname
}

output "dotnet_webapp_ips" {
  value = azurerm_windows_web_app.app.outbound_ip_addresses
}