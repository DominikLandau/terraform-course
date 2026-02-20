locals {
  cert_files = fileset("./cert_imports", "**/*.pfx")
}

output "files" {
  value = local.cert_files
}

resource "azurerm_key_vault_certificate" "infra" {
  name         = "infra-cert"
  key_vault_id = module.kv1.resource_id

  certificate {
    contents = filebase64("./certs/certificate.pfx")
    password = "test"
  }
}

resource "azurerm_key_vault_certificate" "dynamic" {
  for_each = toset(local.cert_files)

  name         = "infra-cert-${replace(each.value, ".pfx", "")}"
  key_vault_id = module.kv1.resource_id

  certificate {
    contents = filebase64("./cert_imports/${each.value}")
    password = "test"
  }
}