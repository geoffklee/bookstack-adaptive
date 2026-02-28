terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.90.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "bookstack_adaptive" {
  source = "../../modules/function-flex-consumption"

  prefix              = var.prefix
  resource_group_name = var.resource_group_name
  location            = var.location

  output_webhook_url = var.output_webhook_url
  output_auth_key    = var.output_auth_key

  vnet_integration = {
    outbound = {
      vnet_name           = var.outbound_vnet_name
      resource_group_name = var.outbound_vnet_resource_group_name
      subnet_name         = var.outbound_subnet_name
    }
    inbound = {
      vnet_name           = var.inbound_vnet_name
      resource_group_name = var.inbound_vnet_resource_group_name
      subnet_name         = var.inbound_subnet_name
    }
  }
}
