# Updated README

## Function App Configuration

This module allows you to create Function Apps with the following variables:

- **function_app_name**: The name of the Function App.
- **service_plan_name**: The name of the service plan associated with the Function App.
- **storage_account_name**: The name of the Storage Account.
- **application_insights_name**: The name of the Application Insights resource.

### Notes
- Ensure that the existing azurerm_log_analytics_workspace has been removed.
- Use classic azurerm_application_insights without workspace.
- Ensure that the storage account is configured with network rules that restrict access:
  - `default_action`: Deny
  - `bypass`: ["AzureServices"]
  - `virtual_network_subnet_ids`: [subnet_id]
- Ensure that outbound VNet integration subnet is used for storage rules.
- Maintain inbound access restrictions.