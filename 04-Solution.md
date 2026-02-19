### Create a DNS Zone
https://github.com/Azure/terraform-azurerm-avm-res-network-dnszone

``` bash
mkdir ~/05 && cd ~/05
```

The easiest way creating a resource from the existing module is by directly referencing the GitHub repo in the module.

``` bash
cat << 'EOF' > provider.tf
terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.60.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
EOF
```

Here we use as a source the GitHub url.
``` bash
cat << 'EOF' > main.tf
module "dns_zones" {
  source = "github.com/Azure/terraform-azurerm-avm-res-network-dnszone"

  name                = "mydns.com"
  resource_group_name = "terraform"
}
EOF
```

To use this module we need to first make it available
``` bash
terraform init
```

Now it is available under:
``` bash
ls .terraform/modules/dns_zones/
```

When we now run a plan command we see three objects being created. One is the DNS zone itself and the two other are for Telemetry for the module developer. More info under: https://github.com/Azure/terraform-provider-modtm
``` bash
terraform plan
```

``` bash
Terraform will perform the following actions:

  # module.dns_zones.azurerm_dns_zone.zone will be created
  + resource "azurerm_dns_zone" "zone" {
      + id                        = (known after apply)
      + max_number_of_record_sets = (known after apply)
      + name                      = "mydns.com"
      + name_servers              = (known after apply)
      + number_of_record_sets     = (known after apply)
      + resource_group_name       = "kurs1"

      + soa_record (known after apply)
    }

  # module.dns_zones.modtm_telemetry.telemetry[0] will be created
  + resource "modtm_telemetry" "telemetry" {
      + ephemeral_number = (known after apply)
      + id               = (known after apply)
      + nonce            = (known after apply)
      + tags             = {
          + "location"        = "unknown"
          + "module_source"   = "git::https://github.com/Azure/terraform-azurerm-avm-res-network-dnszone.git"
          + "module_version"  = null
          + "random_id"       = (known after apply)
          + "subscription_id" = "b839dba6-c92d-4975-8ea0-ec65addc6677"
          + "tenant_id"       = "e9d9e2fa-f59f-4299-ac5d-a4a253abfbb8"
        }
    }

  # module.dns_zones.random_uuid.telemetry[0] will be created
  + resource "random_uuid" "telemetry" {
      + id     = (known after apply)
      + result = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.
```

If we are happy with the result we can now create it.
``` bash
terraform apply
```

```
module.dns_zones.random_uuid.telemetry[0]: Creating...
module.dns_zones.random_uuid.telemetry[0]: Creation complete after 0s [id=e17c8cbe-43e8-de87-1769-51d24e166f57]
module.dns_zones.modtm_telemetry.telemetry[0]: Creating...
module.dns_zones.modtm_telemetry.telemetry[0]: Creation complete after 1s [id=c192d586-0df3-46af-ba0f-1edd1b1a1b71]
module.dns_zones.azurerm_dns_zone.zone: Creating...
module.dns_zones.azurerm_dns_zone.zone: Creation complete after 8s [id=/subscriptions/b839dba6-c92d-4975-8ea0-ec65addc6677/resourceGroups/kurs1/providers/Microsoft.Network/dnsZones/mydns.com]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

To finish everything we can now delete it.
``` bash
terraform destry
```

``` bash
module.dns_zones.modtm_telemetry.telemetry[0]: Destroying... [id=c192d586-0df3-46af-ba0f-1edd1b1a1b71]
module.dns_zones.modtm_telemetry.telemetry[0]: Destruction complete after 0s
module.dns_zones.random_uuid.telemetry[0]: Destroying... [id=e17c8cbe-43e8-de87-1769-51d24e166f57]
module.dns_zones.random_uuid.telemetry[0]: Destruction complete after 0s
module.dns_zones.azurerm_dns_zone.zone: Destroying... [id=/subscriptions/b839dba6-c92d-4975-8ea0-ec65addc6677/resourceGroups/kurs1/providers/Microsoft.Network/dnsZones/mydns.com]
module.dns_zones.azurerm_dns_zone.zone: Still destroying... [id=/subscriptions/b839dba6-c92d-4975-8ea0-...s/Microsoft.Network/dnsZones/mydns.com, 00m10s elapsed]
module.dns_zones.azurerm_dns_zone.zone: Destruction complete after 17s

Destroy complete! Resources: 3 destroyed.
```

### Specifiy by Tag or Commit
There is also the option to use a specific commit or tag as a reference.
``` bash
cat << 'EOF' > main.tf
module "dns_zones" {
  source = "github.com/Azure/terraform-azurerm-avm-res-network-dnszone?ref=v0.2.1"

  name                = "mydns.com"
  resource_group_name = "terraform"
}
EOF
```

If its a correct path an init should work
``` bash
terraform init
```

```
Initializing the backend...
Initializing modules...
Downloading git::https://github.com/Azure/terraform-azurerm-avm-res-network-dnszone.git?ref=v0.2.1 for dns_zones...
- dns_zones in .terraform/modules/dns_zones
```

We can also reference a commit.
``` bash
cat << 'EOF' > main.tf
module "dns_zones" {
  source = "github.com/Azure/terraform-azurerm-avm-res-network-dnszone?ref=b306ad93e180143517846ec03fac0f44694e5869"

  name                = "mydns.com"
  resource_group_name = "terraform"
}
EOF
```

If its a correct path an init should work
``` bash
terraform init
```

```
Initializing the backend...
Initializing modules...
Downloading git::https://github.com/Azure/terraform-azurerm-avm-res-network-dnszone.git?ref=b306ad93e180143517846ec03fac0f44694e5869 for dns_zones...
- dns_zones in .terraform/modules/dns_zones
```

### Working with private repos
In our case the reference to the right repo is quiet easy, because it is public. If the repo is private we need setup the auth accordingly. 

By default the https auth will be used. This can also be seen at at the output above.
```
git::https://github.com/Azure/terraform-azurerm-avm-res-network-dnszone.git
```

It is also possible to use ssh.
```
git::ssh://github.com/Azure/terraform-azurerm-avm-res-network-dnszone.git
```

### Reference a folder in a Repo
Sometimes all the modules are stored in a big repo and we need to download it from a specific folder. For this we need the syntax below. The first part is the same only when referencing the folders we need to start with **//**.
```
git::ssh://github.com/Azure/terraform-azurerm-avm-res-network-dnszone.git//myfolder/anotherone?ref=...
```
