variable "prefix" {
  description = "Short prefix used to name all resources (e.g. 'bsa-prod')."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the existing Azure Resource Group to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region for all resources (e.g. 'eastus')."
  type        = string
}

variable "output_webhook_url" {
  description = "Destination webhook URL the function will forward BookStack events to."
  type        = string
  sensitive   = true
}

variable "output_auth_key" {
  description = "Optional bearer / HMAC key sent with outbound webhook requests."
  type        = string
  sensitive   = true
  default     = ""
}

variable "outbound_vnet_name" {
  description = "Name of the VNet containing the outbound subnet (delegated to Microsoft.Web/serverFarms)."
  type        = string
}

variable "outbound_vnet_resource_group_name" {
  description = "Resource group of the VNet containing the outbound subnet."
  type        = string
}

variable "outbound_subnet_name" {
  description = "Subnet name used for outbound VNet integration (Function App to Storage Account)."
  type        = string
}

variable "inbound_vnet_name" {
  description = "Name of the VNet containing the inbound subnet. May differ from the outbound VNet."
  type        = string
}

variable "inbound_vnet_resource_group_name" {
  description = "Resource group of the VNet containing the inbound subnet."
  type        = string
}

variable "inbound_subnet_name" {
  description = "Subnet whose traffic is allowed inbound to the Function App and SCM endpoints."
  type        = string
}
