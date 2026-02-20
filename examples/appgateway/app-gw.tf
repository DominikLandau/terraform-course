module "test" {
  source = "github.com/Azure/terraform-azurerm-avm-res-network-applicationgateway"

  enable_telemetry    = false
  name                = "agw-prod"
  location            = local.location
  resource_group_name = "kurs1"
 
  autoscale_configuration     = { 
    min_capacity = 1
    max_capacity = 2 
  }
  
  gateway_ip_configuration = {
    name      = "ip_config"
    subnet_id = "/subscriptions/b839dba6-c92d-4975-8ea0-ec65addc6677/resourceGroups/kurs1/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/default"
  }

  public_ip_address_configuration = {
    public_ip_name = "app-gw-pip"
  }

  # Frontend config
  frontend_ports = {
    http  = { name = "http", port = 80 }
    https = { name = "https", port = 443 }
  }
  
  http_listeners = {
    web = {
      name                           = "web-http"
      frontend_port_name             = "http"
      protocol                       = "Http"
      host_names                     = ["test.dominiklandau.de"]
    }
  }

  request_routing_rules = {
    routing-rule-1 = {
      name                       = "rule-1"
      rule_type                  = "Basic"
      http_listener_name         = "web-http"
      backend_address_pool_name  = "mypool1"
      backend_http_settings_name = "default-http"
      priority                   = 100
    }
  }
  
  backend_address_pools = {
    pool1 = {
      name         = "mypool1"
      ip_addresses = ["10.0.2.6", "10.0.2.5"]
    }
  }

  backend_http_settings = {
    default = {
      name                  = "default-http"
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 30
    }
  }
}
