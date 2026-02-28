output "function_app_name" {
  description = "The name of the deployed Linux Function App."
  value       = module.bookstack_adaptive.function_app_name
}

output "function_app_default_hostname" {
  description = "The default hostname of the Function App."
  value       = module.bookstack_adaptive.function_app_default_hostname
}

output "function_app_id" {
  description = "The resource ID of the Function App."
  value       = module.bookstack_adaptive.function_app_id
}

output "storage_account_name" {
  description = "Name of the Storage Account used by the Function App."
  value       = module.bookstack_adaptive.storage_account_name
}
