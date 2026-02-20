locals {
  dns_name = ["api.terra.com", "web.terra.com"]
}

module "mydns" {
  source = "./dns"
  
  for_each = toset(local.dns_name)

  dns_name = each.value
}
