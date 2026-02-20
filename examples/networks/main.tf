locals {
  networks = {
    prod = "/sub/erfeerji"
    test = "/sfsfs"
  }
}

data "azurerm_virtual_network" "prod" {
  resource_group_name = "kurs1"
  name     = "vnet1"
}

module "test" {
  network = data.azurerm_virtual_network.${local.env}
}