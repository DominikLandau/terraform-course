module "kv1" {
  source = "github.com/Azure/terraform-azurerm-avm-res-keyvault-vault"

  location = "germanywestcentral"

  name                = "mykv19353801480808"
  resource_group_name = "kurs1"
  tenant_id           = "e9d9e2fa-f59f-4299-ac5d-a4a253abfbb8"
  enable_telemetry    = "false"

  network_acls = {
    default_action = "Allow"
  }
}
