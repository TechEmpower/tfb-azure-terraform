variable "TFB_SERVER_HOST" { default = "10.0.0.4" }
variable "TFB_DATABASE_HOST" { default = "10.0.0.5" }
variable "TFB_CLIENT_HOST" { default = "10.0.0.6" }
variable "TFB_COMMAND" { default = "techempower/tfb" }
variable "TFB_RESULTS_NAME" { default = "results" }
variable "TFB_RESULTS_ENVIRONMENT" { default = "results_env" }
variable "TFB_UPLOAD_URI" {}
variable "TFB_COMMIT_HASH" { default = "" }

variable "VM_PUBLIC_KEY" {}
variable "VM_PRIVATE_KEY" { default = "to be set" }
variable "VM_ADMIN_USERNAME" {}
variable "VM_ALLOWED_IP" {}

variable "AZURE_CLIENT_ID" {}
variable "AZURE_CLIENT_SECRET" {}
variable "AZURE_STORAGE_ACCOUNT_NAME" {}
variable "AZURE_STORAGE_CONTAINER_NAME" {}
variable "AZURE_STORAGE_RESOURCE_GROUP_NAME" {}
variable "AZURE_TEARDOWN_TRIGGER_URL" {}
variable "AZURE_TENANT_ID" {}

terraform {
  required_version = ">= 0.12.6"

  backend "azurerm" {}
}

provider "azurerm" {
  version = "=1.28.0"
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "tfb-azure-terraform-process"
  location = "Central US"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "main" {
  name                = "tfb-virtual-network"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
  address_space       = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "10.0.0.0/24"
}
