variable "prefix" {
  description = "Short prefix used to name all resources (e.g. 'bsa-prod'). Must be lowercase and may contain hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,20}[a-z0-9]$", var.prefix))
    error_message = "prefix must be 3-22 characters, start and end with a lowercase letter or digit, and contain only lowercase letters, digits, or hyphens."
  }
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
  description = "Destination webhook URL the function will forward BookStack events to. Stored as app setting OUTPUT_WEBHOOK_URL."
  type        = string
  sensitive   = true
}

variable "output_auth_key" {
  description = "Optional bearer / HMAC key sent with outbound webhook requests. Stored as app setting OUTPUT_AUTH_KEY."
  type        = string
  sensitive   = true
  default     = ""
}

variable "vnet_integration" {
  description = "VNet integration and inbound-restriction configuration."
  type = object({
    vnet_name                = string
    vnet_resource_group_name = string
    subnet_name              = string
  })
}
