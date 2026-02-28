output "function_app_name" {
  description = "The name of the deployed Linux Function App."
  value       = azurerm_linux_function_app.main.name
}

output "function_app_default_hostname" {
  description = "The default hostname of the Function App (e.g. <name>.azurewebsites.net)."
  value       = azurerm_linux_function_app.main.default_hostname
}

output "function_app_id" {
  description = "The resource ID of the Function App."
  value       = azurerm_linux_function_app.main.id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key."
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string."
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "storage_account_name" {
  description = "Name of the Storage Account used by the Function App."
  value       = azurerm_storage_account.main.name
}
