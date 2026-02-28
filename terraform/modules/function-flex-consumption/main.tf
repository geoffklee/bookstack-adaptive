locals {
  # Storage account names: 3-24 chars, lowercase alphanumeric only.
  # Strip hyphens from prefix and append "sa", truncated to 24 characters.
  storage_account_name = substr(lower(replace("${var.prefix}sa", "-", "")), 0, 24)

  function_app_name  = "${var.prefix}-func"
  service_plan_name  = "${var.prefix}-asp"
  app_insights_name  = "${var.prefix}-ai"
  log_analytics_name = "${var.prefix}-law"
}

# ---------------------------------------------------------------------------
# Data sources
# ---------------------------------------------------------------------------

data "azurerm_subnet" "outbound" {
  name                 = var.vnet_integration.outbound.subnet_name
  virtual_network_name = var.vnet_integration.outbound.vnet_name
  resource_group_name  = var.vnet_integration.outbound.resource_group_name
}

data "azurerm_subnet" "inbound" {
  name                 = var.vnet_integration.inbound.subnet_name
  virtual_network_name = var.vnet_integration.inbound.vnet_name
  resource_group_name  = var.vnet_integration.inbound.resource_group_name
}

# ---------------------------------------------------------------------------
# Storage Account (required by Azure Functions runtime)
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

# ---------------------------------------------------------------------------
# Log Analytics Workspace (backing store for workspace-based App Insights)
# ---------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = local.log_analytics_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# ---------------------------------------------------------------------------
# Application Insights (workspace-based)
# ---------------------------------------------------------------------------

resource "azurerm_application_insights" "main" {
  name                = local.app_insights_name
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
}

# ---------------------------------------------------------------------------
# Flex Consumption service plan  (sku FC1 = Flex Consumption)
# ---------------------------------------------------------------------------

resource "azurerm_service_plan" "main" {
  name                = local.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "FC1"
}

# ---------------------------------------------------------------------------
# Linux Function App
# ---------------------------------------------------------------------------

resource "azurerm_linux_function_app" "main" {
  name                = local.function_app_name
  resource_group_name = var.resource_group_name
  location            = var.location

  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  # Outbound VNet integration routes function traffic (e.g. to Storage Account)
  # through the designated outbound subnet.
  virtual_network_subnet_id = data.azurerm_subnet.outbound.id

  app_settings = {
    OUTPUT_WEBHOOK_URL                    = var.output_webhook_url
    OUTPUT_AUTH_KEY                       = var.output_auth_key
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.main.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.main.connection_string
    # Deploy via zip package; the package URL is provided out-of-band (e.g. CI/CD).
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  site_config {
    application_stack {
      python_version = "3.13"
    }

    # Inbound restriction: allow only traffic from the inbound subnet.
    ip_restriction_default_action = "Deny"

    ip_restriction {
      name                       = "allow-inbound-subnet"
      virtual_network_subnet_id  = data.azurerm_subnet.inbound.id
      action                     = "Allow"
      priority                   = 100
    }

    # Lock SCM (Kudu) to the same inbound subnet.
    scm_ip_restriction_default_action = "Deny"

    scm_ip_restriction {
      name                       = "allow-inbound-subnet-scm"
      virtual_network_subnet_id  = data.azurerm_subnet.inbound.id
      action                     = "Allow"
      priority                   = 100
    }
  }
}
