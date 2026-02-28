# Bookstack Adaptive – Terraform

Terraform code to deploy the **Bookstack Adaptive** Azure Function App on an
Azure Functions **Flex Consumption** plan.

## Structure

```
terraform/
├── README.md                          # this file
├── modules/
│   └── function-flex-consumption/    # reusable module
│       ├── versions.tf
│       ├── variables.tf
│       ├── main.tf
│       └── outputs.tf
└── examples/
    └── basic/                         # minimal end-to-end example
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars.example
```

## Required Providers

| Provider | Source | Minimum version |
|---|---|---|
| `azurerm` | `hashicorp/azurerm` | `>= 3.90.0` |

Authenticate using any supported method (Azure CLI, service principal environment
variables, Workload Identity, etc.).  
See the [AzureRM provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs).

## Quick Start

```bash
cd terraform/examples/basic

# 1. Copy and populate the example vars file
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars        # fill in real values

# 2. Initialise and plan
terraform init
terraform plan

# 3. Apply
terraform apply
```

## Module: `function-flex-consumption`

### Required Inputs

| Variable | Type | Description |
|---|---|---|
| `prefix` | `string` | Short lowercase prefix for resource names (3-22 chars, hyphens allowed). |
| `resource_group_name` | `string` | Name of an **existing** Azure Resource Group. |
| `location` | `string` | Azure region (e.g. `eastus`). |
| `output_webhook_url` | `string` (sensitive) | Destination webhook URL stored as `OUTPUT_WEBHOOK_URL` app setting. |
| `vnet_integration` | `object` | VNet integration config – see below. |

### Optional Inputs

| Variable | Type | Default | Description |
|---|---|---|---|
| `output_auth_key` | `string` (sensitive) | `""` | Optional auth key stored as `OUTPUT_AUTH_KEY` app setting. |

### `vnet_integration` Object

```hcl
vnet_integration = {
  vnet_name                = "vnet-main"
  vnet_resource_group_name = "rg-networking"
  subnet_name              = "snet-functions"
}
```

The module looks up the subnet via `data "azurerm_subnet"` and uses the
resulting resource ID for both outbound VNet integration and inbound
IP restrictions.

### Resources Created

| Resource | Purpose |
|---|---|
| `azurerm_storage_account` | Required by the Functions runtime. |
| `azurerm_log_analytics_workspace` | Backing workspace for Application Insights. |
| `azurerm_application_insights` | Workspace-based Application Insights instance. |
| `azurerm_service_plan` (FC1) | Flex Consumption hosting plan. |
| `azurerm_linux_function_app` | The Python 3.13 Function App. |

### Outputs

| Output | Description |
|---|---|
| `function_app_name` | Name of the Function App. |
| `function_app_default_hostname` | Default hostname (`<name>.azurewebsites.net`). |
| `function_app_id` | Azure resource ID of the Function App. |
| `storage_account_name` | Name of the created Storage Account. |
| `application_insights_instrumentation_key` | Instrumentation key (sensitive). |
| `application_insights_connection_string` | Connection string (sensitive). |

## Networking Notes

### Outbound VNet Integration

The Function App routes **outbound** traffic through the configured subnet via
`virtual_network_subnet_id` on the `azurerm_linux_function_app` resource.
The subnet must have **service delegation** to `Microsoft.Web/serverFarms`.

### Inbound Restrictions

The module configures `ip_restriction` and `scm_ip_restriction` in `site_config`
to allow inbound traffic only from the configured subnet
(`virtual_network_subnet_id`). The default action is **Deny**.

> **Important:** Azure Functions always has a public endpoint
> (`<name>.azurewebsites.net`). The IP restrictions do **not** remove this
> endpoint; they instruct Azure to drop requests that originate outside the
> allowed subnet. For a fully private endpoint, consider adding a Private
> Endpoint and disabling public access separately.

## Deploying Code After Infra

The Terraform code provisions infrastructure only. To deploy the function code:

```bash
# From the repo root – package and publish via Azure Functions Core Tools
func azure functionapp publish <function-app-name>

# Or use the Azure CLI zip deploy
az functionapp deployment source config-zip \
  --resource-group <resource-group> \
  --name <function-app-name> \
  --src build/function.zip
```

`WEBSITE_RUN_FROM_PACKAGE=1` is pre-configured as an app setting, so the
runtime will load the deployed package directly from the zip.

## Sensitive Variables

Never commit `terraform.tfvars` to source control. Prefer supplying sensitive
values via environment variables:

```bash
export TF_VAR_output_webhook_url="https://hooks.example.com/..."
export TF_VAR_output_auth_key="supersecret"
```
