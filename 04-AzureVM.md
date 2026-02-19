### Create a simple Azure VM
``` bash
mkdir ~/03 && cd ~/03
```

There are a lot of different ways to authenticate against Azure.
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure
To keep it simple we use an App Registration with a secret. So the first step is to create the SP, then create a secret for it and at last give it access to an Resource Group.

When using the App Registration we need to pass four values to authenticate against Azure. First the Tenant and Subscription id, to identify the environment, then the Client and Client Secret to specify the SP. Here I do it with environment variables.
``` bash
export ARM_CLIENT_ID="XXX"
export ARM_CLIENT_SECRET="XXX"
export ARM_TENANT_ID="  
84b9c75c-6119-410c-b1a3-9ba823871b4c"
export ARM_SUBSCRIPTION_ID="3e55f3dd-c992-4916-bd68-6214b2f5aaa6"
```

An other way would be placing these values directly in the provider block.
```
provider "azurerm" {
  features {}

  client_id       = "00000000-0000-0000-0000-000000000000"
  client_secret   = var.client_secret
  tenant_id       = "10000000-0000-0000-0000-000000000000"
  subscription_id = "20000000-0000-0000-0000-000000000000"
}
```

After exporting the environment variables we create the needed provider block first.
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

Now we define a main.tf file which contains all the code to create a virtual machine. Look through the code and try to understand it.
``` bash
cat << 'EOF' > main.tf
data "azurerm_resource_group" "rg" {
  name     = var.rg-name
}

# Create virtual network
resource "azurerm_virtual_network" "network" {
  name                = "${var.user-id}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.user-id}-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "pip" {
  name                = "${var.user-id}-public-ip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.user-id}-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.user-id}-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# Random password generator (12 chars, letters + numbers)
resource "random_password" "admin_pass" {
  length           = 12
  special          = false
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_linux_virtual_machine" "ubuntu" {
  name                            = "${var.user-id}-ubuntu2404-vm"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = "Standard_B1ms"
  admin_username                  = "ubuntuuser"
  admin_password                  = random_password.admin_pass.result
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
EOF
```

Now we need to create the variables.tf file to set the variables. Change the defaults to the right values.
``` bash
cat << 'EOF' > variables.tf
variable "user-id" {
  type = string
  default = "dominik"
}

variable "rg-name" {
  type = string
  default = "terraform"
}
EOF
```

We also create an output.tf file which will be later used.
``` bash
cat << 'EOF' > output.tf
# Outputs
output "vm_ip_address" {
  description = "Public IP address of the Ubuntu VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_username" {
  description = "Admin username"
  value       = azurerm_linux_virtual_machine.ubuntu.admin_username
}

output "vm_password" {
  description = "Admin password (sensitive)"
  value       = random_password.admin_pass.result
  sensitive   = true
}
EOF
```

``` bash
ls
```
Now we should see four files
```
main.tf  output.tf  provider.tf  variables.tf
```

Initialize Terraform with:
``` bash
terraform init
```

If everything is correctly setup, we can now create a virtual machine
``` bash
terraform plan
```

```
data.azurerm_resource_group.rg: Reading...
data.azurerm_resource_group.rg: Read complete after 0s [id=/subscriptions/b839dba6-c92d-4975-8ea0-ec65addc6677/resourceGroups/kurs1]

...

Plan: 8 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + vm_ip_address = (known after apply)
  + vm_password   = (sensitive value)
  + vm_username   = "ubuntuuser"
```

Now create the VM
``` bash
terraform apply -auto-approve
```

After an successful creation we will now delete the VM
``` bash
terraform destroy
```

### Create a Module
Creating a single VM with the Terraform code form before is quiet easy, but scaling it would be difficult. So that we don't have to copy the code over and over again we can use the Terraform Module funktionality.

For this we create a new folder and switch into it.

``` bash
mkdir ~/04 && cd ~/04
```

Creating a Module is quiet easy, we first need some valid Terraform code. For this we use the code from before. Now we only need the code below to define a Module out of it.
``` bash
cat << 'EOF' > main.tf
module "my-module" {
  source = "../03"
}
EOF
```

Like always a terraform plan directly doesn't work.
``` bash
terraform plan
```

```
╷
│ Error: Module not installed
│ 
│   on main.tf line 1:
│    1: module "my-module" {
│
│ This module is not yet installed. Run "terraform init" to install all modules required by this configuration.
╵
```

We start with terraform get to load the module
``` bash
terraform get
```

```
- my-module in ../03
```

Now a reference to the module is created
``` bash
cat .terraform/modules/modules.json | jq
```

```
{
  "Modules": [
    {
      "Key": "",
      "Source": "",
      "Dir": "."
    },
    {
      "Key": "my-module",
      "Source": "../03",
      "Dir": "../03"
    }
  ]
}
```

If the terraform plan is executed now we still get an error, because the provider dependencies are missing.

``` bash
terraform plan
```

```
╷
│ Error: Inconsistent dependency lock file
│
│ The following dependency selections recorded in the lock file are inconsistent with the current configuration:
│   - provider registry.terraform.io/hashicorp/azurerm: required by this configuration but no version is selected
│   - provider registry.terraform.io/hashicorp/random: required by this configuration but no version is selected
│
│ To make the initial dependency selections that will initialize the dependency lock file, run:
│   terraform init
|
```

So we download the missing dependencies with:
``` bash
terraform init
```

With the plan command we can now create the VM with the default config.
``` bash
terraform plan
```

```
Plan: 8 to add, 0 to change, 0 to destroy.
```

We can also modify the variables in the module. For this we make some changes to the main.tf.
``` bash
cat << 'EOF' > main.tf
module "my-module" {
  source = "../03"
  
  user-id = "someone"  # change
}
EOF
```

If we now look into the names of the resources Terraform wants to create we can the value of user-id.
``` bash
terraform plan
```

Additionally we can also extract data out of the module with the outputs.
``` bash
cat << 'EOF' > output.tf
output "from-module" {
  value = module.my-module.vm_ip_address
}
EOF
```

Here we extract the ip address of the VM
``` bash
terraform plan
```

```
Plan: 8 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + from-module = (known after apply)
```

### Azure Verified Modules
Creating all the modules by yourselves is a lot of work. So instead of doing it, we can use the modules Azure recommends.

Have a look at:
https://azure.github.io/Azure-Verified-Modules/

Here is also a pre defined module for the Azure VMs:
https://github.com/Azure/terraform-azurerm-avm-res-compute-virtualmachine

If you look at it, it is quiet complex. So for easier use we will use the DNS module:
https://github.com/Azure/terraform-azurerm-avm-res-network-dnszone/tree/main

Taks: Try to use the DNS module to create a dns zone.
