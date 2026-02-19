### Creating multiple resources
Looping over a variable is an important part of creating multiple resources at one. 

``` bash
mkdir ~/06 && cd ~/06
```

``` bash
cat << 'EOF' > provider.tf
terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.60.0"
    }
  }
}

provider "azurerm" {
  features {}
}
EOF
```

Init Terraform
``` bash
terraform init
```

### For_each
Fist we start with the for_each.
Here we pass either set or a map of values over which Terraform iterates. During the iteration we can access the key by each.key and the values by each.value.
``` bash
cat << 'EOF' > foreach.tf
locals {
  dns_zones = {
    "app1" = "app1.example.com"
    "api"  = "api.internal.com"
    "web"  = "web.public.com"
  }
}

# Multiple DNS zones with for_each
resource "azurerm_dns_zone" "zones" {
  for_each = local.dns_zones

  name                = "${each.value}-${each.key}"
  resource_group_name = "kurs1"

  tags = {
    Environment = each.key
    Purpose     = "demo"
  }
}
EOF
```

If we run a plan now, we can see, that three resources will be created.
``` bash
terraform plan
```

```
  # azurerm_dns_zone.zones["web"] will be created
  + resource "azurerm_dns_zone" "zones" {
      + id                        = (known after apply)
      + max_number_of_record_sets = (known after apply)
      + name                      = "web.public.com-web"
      + name_servers              = (known after apply)
      + number_of_record_sets     = (known after apply)
      + resource_group_name       = "kurs1"
      + tags                      = {
          + "Environment" = "web"
          + "Purpose"     = "demo"
        }

      + soa_record (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.
```

If we look at the names of the resources we can see the combination of the key and value of the map used. An other important part is the Terraform state path of the resource, which also represents the map. Each resource id is prefixed with square brackets with the key of the map inside. That is also the reason, why Terraform throws an error if you want to use a list with the for_each argument. 

We don't need to create the resources analysing the plan output is enough.

Lets try it with a set.
``` bash
cat << 'EOF' > foreach.tf
variable "dns_zones" {
  type = set(string)
  default = ["api.com", "web.com"]
}

resource "azurerm_dns_zone" "zones1" {
  for_each = var.dns_zones

  name                = "${each.value}-${each.key}"
  resource_group_name = "kurs1"
}
EOF
```

This also works without a problem.
``` bash
terraform plan
```

```
  # azurerm_dns_zone.zones1["web.com"] will be created
  + resource "azurerm_dns_zone" "zones1" {
      + id                        = (known after apply)
      + max_number_of_record_sets = (known after apply)
      + name                      = "web.com-web.com"
      + name_servers              = (known after apply)
      + number_of_record_sets     = (known after apply)
      + resource_group_name       = "kurs1"

      + soa_record (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

Now we try it with a list
``` bash
cat << 'EOF' > foreach.tf
variable "dns_zones" {
  type = list(string)
  default = ["api.com", "web.com"]
}

resource "azurerm_dns_zone" "zones2" {
  for_each = var.dns_zones

  name                = "${each.value}-${each.key}"
  resource_group_name = "kurs1"
}

EOF
```

Here we get the error earlier described.
``` bash
terraform plan
```

```
╷
│ Error: Invalid for_each argument
│
│   on foreach.tf line 7, in resource "azurerm_dns_zone" "zones2":
│    7:   for_each = var.dns_zones
│     ├────────────────
│     │ var.dns_zones is a list of string
│
│ The given "for_each" argument value is unsuitable: the "for_each" argument must be a map, or set of strings, and   
│ you have provided a value of type list of string.
|
```

To solve this we can use the toset() function and convert the list to a set. But keep in mind, that duplicate values get lost!
``` bash
cat << 'EOF' > foreach.tf
variable "dns_zones" {
  type = list(string)
  default = ["api.com", "web.com"]
}

resource "azurerm_dns_zone" "zones2" {
  for_each = toset(var.dns_zones)  # toset()

  name                = "${each.value}-${each.key}"
  resource_group_name = "kurs1"
}

EOF
```

Now it works!
``` bash
terraform plan
```

```
  # azurerm_dns_zone.zones2["web.com"] will be created
  + resource "azurerm_dns_zone" "zones2" {
      + id                        = (known after apply)
      + max_number_of_record_sets = (known after apply)
      + name                      = "web.com-web.com"
      + name_servers              = (known after apply)
      + number_of_record_sets     = (known after apply)
      + resource_group_name       = "kurs1"

      + soa_record (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

The last example with the for_each is a little bit more complex. Here we use a map of maps over which we will iterate
``` bash
cat << 'EOF' > foreach.tf
locals {
  dns_zones = {
    "app1" = {
      name = "myapp"
      dns  = "app1.example.com"
    }
    "api"  = {
      name = "otherapp"
      dns  = "api.example.com"
    }
  }
}

# Multiple DNS zones with for_each
resource "azurerm_dns_zone" "zones" {
  for_each = local.dns_zones

  name                = "${each.value.dns}-${each.key}"
  resource_group_name = each.value["dns"]
}
EOF
```

The plan also works here. The big difference here is, that the each.value is not a simple string, it is a map. So we can access the value either with each.value.dns or with each.value\["dns"].
``` bash
terraform plan
```

```
  # azurerm_dns_zone.zones["app1"] will be created
  + resource "azurerm_dns_zone" "zones" {
      + id                        = (known after apply)
      + max_number_of_record_sets = (known after apply)
      + name                      = "app1.example.com-app1"
      + name_servers              = (known after apply)
      + number_of_record_sets     = (known after apply)
      + resource_group_name       = "app1.example.com"
      + tags                      = {
          + "Environment" = "app1"
          + "Purpose"     = "demo"
        }

      + soa_record (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

Remove the foreach.tf so it doesn't produce any output
``` bash
rm foreach.tf
```

### Count
With the count we can specify a specific number of instances we want to have. 
``` bash
cat << 'EOF' > count.tf
locals {
  zone_names = ["app.example.com", "api.example.com", "web.example.com"]
}

# Create DNS zones with count
resource "azurerm_dns_zone" "zone" {
  count = length(local.zone_names)

  name                = local.zone_names[count.index]
  resource_group_name = "kurs1"

  tags = {
    env = "zone-${count.index}"
  }
}
EOF
```

The example above could be also solved with a for_each, but for demonstration a count is used. During the execution we get a variable with the current index starting with 0 (count.index).
``` bash
terraform plan
```

```
  # azurerm_dns_zone.zone[2] will be created
  + resource "azurerm_dns_zone" "zone" {
      + id                        = (known after apply)
      + max_number_of_record_sets = (known after apply)
      + name                      = "web.example.com"
      + name_servers              = (known after apply)
      + number_of_record_sets     = (known after apply)
      + resource_group_name       = "kurs1"
      + tags                      = {
          + "env" = "zone-2"
        }

      + soa_record (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.
```

The typical use case for count is to decide if a resource should be created or not based on the value of a Boolean variable.
``` bash
cat << 'EOF' > count.tf
variable "enable_dns" {
  type = bool
  description = "Whether to create the DNS zone"
  default = true
}

# Create DNS zones with count
resource "azurerm_dns_zone" "zone" {
  count = var.enable_dns ? 1 : 0

  name                = "mydns-zone"
  resource_group_name = "kurs1"
}
EOF
```

If we run the plan by default the DNS zone will be created
``` bash
terraform plan
```

```
  # azurerm_dns_zone.zone[0] will be created
  + resource "azurerm_dns_zone" "zone" {
      + id                        = (known after apply)
      + max_number_of_record_sets = (known after apply)
      + name                      = "mydns-zone"
      + name_servers              = (known after apply)
      + number_of_record_sets     = (known after apply)
      + resource_group_name       = "kurs1"

      + soa_record (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

If we set the variable to false, the zone wont be created.
``` bash
terraform plan -var enable_dns=false
```

```
No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes   
are needed.
```

Remove the count.tf so it doesn't produce any output
``` bash
rm count.tf
```

### For
With the for key word we can transform variables.

``` bash
cat << 'EOF' > for.tf
locals {
  # 1) Simple list of zone names
  zone_names = [
    "app.example.com", 
    "api.example.com", 
    "web.example.com"
  ]

  # 2) Transform with for expression → list of objects
  zone_configs = [
    for i, name in local.zone_names : {
      index     = i
      name      = name
      ip        = "10.0.0.${i + 10}"
      ttl       = 300
      record    = "www"
      env       = "env-${i}"
    }
  ]
}

output "configs" {
  value = local.zone_configs
}
EOF
```

If we run the plan we can see, that a new map will be created.
``` bash
terraform plan
```

```
Changes to Outputs:
  + configs = [
      + {
          + env    = "env-0"
          + index  = 0
          + ip     = "10.0.0.10"
          + name   = "app.example.com"
          + record = "www"
          + ttl    = 300
        },
      + {
          + env    = "env-1"
          + index  = 1
          + ip     = "10.0.0.11"
          + name   = "api.example.com"
          + record = "www"
          + ttl    = 300
        },
      + {
          + env    = "env-2"
          + index  = 2
          + ip     = "10.0.0.12"
          + name   = "web.example.com"
          + record = "www"
          + ttl    = 300
        },
    ]
```


Adding an if.
It is possible to filter the values with an if like below, where we only want a specific name.
``` bash
cat << 'EOF' > for.tf
locals {
  # 1) Simple list of zone names
  zone_names = [
    "app.example.com", 
    "api.example.com", 
    "web.example.com"
  ]

  # 2) Transform with for expression → list of objects
  zone_configs = [
    for i, name in local.zone_names : {
      index     = i
      name      = name
      ip        = "10.0.0.${i + 10}"
      ttl       = 300
      record    = "www"
      env       = "env-${i}"
    } if name == "web.example.com" ## added if
  ]
}

output "configs" {
  value = local.zone_configs
}
EOF
```

The output contains now only one object
``` bash
terraform plan
```

``` 
Changes to Outputs:
  + configs = [
      + {
          + env    = "env-2"
          + index  = 2
          + ip     = "10.0.0.12"
          + name   = "web.example.com"
          + record = "www"
          + ttl    = 300
        },
    ]
```

Combining it with  for_each
``` bash
cat << 'EOF' > for.tf
locals {
  dns_zones = {
    "app1" = {
      name = "myapp"
      dns  = "app1.example.com"
    }
    "api"  = {
      name = "otherapp"
      dns  = "api.example.com"
    }
  }
}

# Multiple DNS zones with for_each
resource "azurerm_dns_zone" "zones" {
  for_each = {
    for k, v in local.dns_zones :
    "${k}-${v.name}" => {
      mydns = v.dns
      myname = k
    }
  }

  name                = each.value.mydns
  resource_group_name = each.key
}

output "myout" {
  value = {
    for k, v in local.dns_zones :
    "${k}-${v.name}" => {
      mydns = v.dns
      myname = k
    }
  }
}
EOF
```

In this example we rearrange the content of the variable dns_zone. 
1. We iterate over the dns_zone variable
2. We create a new map with the key based on the key of the previous map combined with the name.
3. Create two entries in the map based on the previous key and dns
``` bash
terraform plan
```

```
Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + myout = {
      + api-otherapp = {
          + mydns  = "api.example.com"
          + myname = "api"
        }
      + app1-myapp   = {
          + mydns  = "app1.example.com"
          + myname = "app1"
        }
    }
```


Remove the for.tf so it doesn't produce any output
``` bash
rm for.tf
```

### Dynamic blocks
Some resources in Terraform have a block inside which can be added multiple times. A good example would be the NIC. This object can have an public an private ip address which each is represented by the ip_configuration block.
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface

``` bash
cat << 'EOF' > dynamic.tf
# Variable for IP configurations
variable "ip_configs" {
  type = list(any)
  default = [
    {
      name = "internal"
      allo = "Static"
      ip   = "10.0.1.100"
    },
    {
      name = "external"
      allo = "Static"
      ip   = "10.0.1.101"
    },
  ]
}

# Network Interface with dynamic ip_configuration blocks
resource "azurerm_network_interface" "nic" {
  name                = "dynamic-nic"
  location            = "germanywestcentral"
  resource_group_name = "kurs1"

  # Dynamic block: one ip_configuration per list item
  dynamic "ip_configuration" {
    for_each = var.ip_configs
    content {
      name                          = ip_configuration.value.name
      private_ip_address_allocation = ip_configuration.value.allo

      private_ip_address = ip_configuration.value.ip
    }
  }
}
EOF
```

If we execute the plan, we can see two ip_configuration blocks.
``` bash
terraform plan
```

```
      + ip_configuration {
          + gateway_load_balancer_frontend_ip_configuration_id = (known after apply)
          + name                                               = "internal"
          + primary                                            = (known after apply)
          + private_ip_address                                 = "10.0.1.100"
          + private_ip_address_allocation                      = "Static"
          + private_ip_address_version                         = "IPv4"
        }
      + ip_configuration {
          + gateway_load_balancer_frontend_ip_configuration_id = (known after apply)
          + name                                               = "external"
          + primary                                            = (known after apply)
          + private_ip_address                                 = "10.0.1.101"
          + private_ip_address_allocation                      = "Static"
          + private_ip_address_version                         = "IPv4"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```
