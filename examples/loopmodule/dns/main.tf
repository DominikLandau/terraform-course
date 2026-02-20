variable "dns_name" {
  type = string
}

resource "azurerm_dns_zone" "intenral" {
  name                = var.dns_name
  resource_group_name = "kurs1"
}
