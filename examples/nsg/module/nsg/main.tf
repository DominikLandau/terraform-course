resource "azurerm_network_security_group" "this" {
  resource_group_name = var.nsg_resource_group_name
  location            = var.nsg_location
  name                = var.nsg_name
}

resource "azurerm_network_security_rule" "predefinded" {
  for_each                    = { for rule in var.nsg_predefined_rules : rule => local.predefined_rules[rule] }
  resource_group_name         = azurerm_network_security_group.this.resource_group_name
  network_security_group_name = azurerm_network_security_group.this.name
  direction                   = each.value[0]
  name                        = each.value[1]
  priority                    = each.value[2]
  access                      = each.value[3]
  protocol                    = each.value[4]
  description                 = each.value[5]
  source_address_prefixes     = each.value[6]
  source_port_range           = each.value[7]
  destination_address_prefix  = each.value[8]
  destination_port_range      = each.value[9]
}
