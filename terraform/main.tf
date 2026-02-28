# Example of Terraform code for Function App using Classic Application Insights and storage account network rules.

resource "azurerm_application_insights" "example" {
  name                = var.application_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier            = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action = "Deny"
    bypass        = ["AzureServices"]
    virtual_network_subnet_ids = [var.outbound_subnet_id]
  }
}

resource "azurerm_function_app" "example" {
  name                = var.function_app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  app_service_plan_id = azurerm_service_plan.example.id

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    // Add other necessary app settings here
  }
}

variable "application_insights_name" {
  type        = string
  description = "The name of the Application Insights"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the Storage Account"
}

variable "function_app_name" {
  type        = string
  description = "The name of the Function App"
}

variable "outbound_subnet_id" {
  type = string
  description = "The ID of the outbound subnet for the storage account network rules."
}

variable "location" {
  type        = string
  description = "The location of all resources"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group"
}