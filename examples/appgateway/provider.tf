terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0, < 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  tenant_id       = "e9d9e2fa-f59f-4299-ac5d-a4a253abfbb8"
  client_secret   = "WRe8Q~ePOGW1MmCIOjPHGbITTke5xOZYgnbJ7c~x"
  subscription_id = "b839dba6-c92d-4975-8ea0-ec65addc6677"
  client_id       = "aeade839-4b81-488d-8d60-de50d12069ab"
}