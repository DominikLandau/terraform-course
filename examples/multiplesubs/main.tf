resource "azurerm_dns_zone" "default-provider" {
  name                = "devault-provder.com"
  resource_group_name = "kurs1"
}

resource "azurerm_dns_zone" "sub1-provider" {
  provider = azurerm.sub1

  name                = "sub1-provder.com"
  resource_group_name = "kurs1"
}

resource "azurerm_dns_zone" "sub2-provider" {
  provider = azurerm.sub2
  
  name                = "sub2-provder.com"
  resource_group_name = "kurs1"
}