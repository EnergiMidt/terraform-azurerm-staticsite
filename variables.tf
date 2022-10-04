variable "environment" {
  description = "(Required) The name of the environment."
  default     = null
  type        = string
  validation {
    condition = contains([
      "dev",
      "test",
      "prod",
    ], var.environment)
    error_message = "Possible values are dev, test, and prod."
  }
}

variable "name" {
  description = "(Required) Specifies the name of the storage account. Only lowercase Alphanumeric characters allowed. Changing this forces a new resource to be created. This must be unique across the entire Azure service, not just within the resource group."
  type        = string
}

variable "override_name" {
  description = "(Optional) Override the name of the resource. Under normal circumstances, it should not be used."
  default     = null
  type        = string
}

variable "override_location" {
  description = "(Optional) Override the location of the resource. Under normal circumstances, it should not be used."
  default     = null
  type        = string
}

variable "resource_group" {
  description = "(Required) The resource group in which to create the Storage Account component."
  type        = any
}

# This `resource_group_name` variable is replaced by the use of `resource_group` variable.
# variable "resource_group_name" {
#   description = "(Required) The name of the resource group in which the Log Analytics workspace is created. Changing this forces a new resource to be created."
#   type        = string
# }

# This `location` variable is replaced by the use of `resource_group` variable.
# variable "location" {
#   description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
#   type        = string
# }

variable "sku_tier" {
  description = "(Optional) Specifies the SKU tier of the Static Web App. Possible values are `Free` or `Standard`. Defaults to `Free`."
  type        = string
  default     = "Free"
}

variable "sku_size" {
  description = "(Optional) Specifies the SKU size of the Static Web App. Possible values are `Free` or `Standard`. Defaults to `Free`."
  type        = string
  default     = "Free"
}

variable "identity" {
  default = {
    type = "SystemAssigned"
  }
  description = "(Optional) An identity block as defined below which contains the Managed Service Identity information for this resource."
  type = object(
    {
      type         = string                 # (Required) The Type of Managed Identity assigned to this Static Site resource. Possible values are `SystemAssigned`, `UserAssigned` and `SystemAssigned, UserAssigned`.
      identity_ids = optional(list(string)) # (Optional) The Principal ID associated with this Managed Service Identity.
    }
  )
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the resource."
  default     = {}
  type        = map(string)
}
