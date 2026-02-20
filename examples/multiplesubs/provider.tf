terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.60.0"
    }
  }
}

provider "azurerm" {
  features {}

  tenant_id       = "e9d9e2fa-f59f-4299-ac5d-a4a253abfbb8"
  subscription_id = "b839dba6-c92d-4975-8ea0-ec65addc6677"
}

provider "azurerm" {
  features {}
  alias = "sub1"

  tenant_id       = "e9d9e2fa-f59f-4299-ac5d-a4a253abfbb8"
  subscription_id = "b839dba6-c92d-4975-8ea0-ec65addc6677"
}

provider "azurerm" {
  features {}
  alias = "sub2"

  tenant_id       = "e9d9e2fa-f59f-4299-ac5d-a4a253abfbb8"
  subscription_id = "b839dba6-c92d-4975-8ea0-ec65addc6677"
}