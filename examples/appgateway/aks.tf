data "azurerm_resource_group" "this" {
  name     = "kurs1"
}

module "aks" {
  source = "github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster"

  enable_telemetry = false
  location  = local.location
  name      = "aks1"
  parent_id = data.azurerm_resource_group.this.id
  
  auto_upgrade_profile = {
    upgrade_channel = "none"
  }
  default_agent_pool = {
    vm_size = "Standard_DS2_v2"
    max_count = 1
    min_count = 1
  }

  api_server_access_profile = {
    enable_vnet_integration = "true"
    vnet_subnet_id = "subscriptions/b839dba6-c92d-4975-8ea0-ec65addc6677/resourceGroups/kurs1/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/default"
  }

  addon_profile_ingress_application_gateway = {
    config = {
      application_gateway_id = module.test.application_gateway_id
    }
    enabled = true
  }
  dns_prefix = "defaultexample"

  sku = {
    tier = "Standard"
    name = "Base"
  }
}