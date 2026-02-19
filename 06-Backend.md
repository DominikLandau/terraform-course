Backends are an important part of Terraform, it defines where the tfstate file should be placed. By default it will use the local folder and name the file terraform.tfstate.

``` bash
mkdir ~/07 && cd ~/07
```

Here we will use the local provider for simplicity again.
``` bash
cat << 'EOF' > provider.tf
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "local" {}
EOF
```
Download the provider
``` bash
terraform init
```

Create the first file.
``` bash
cat << 'EOF' > main.tf
# Create a file as a resource
resource "local_file" "generated" {
  filename        = "${path.module}/generated.txt"
  content         = "Hello from Terraform\n"
  file_permission = "0644"
}
EOF
```

Create the resource and look at the created state file
``` bash
terraform apply -auto-approve
```

The terraform.tfstate file is created.
``` bash
ls
```

```
generated.txt  main.tf  provider.tf  terraform.tfstate
```

Now we change the backend config.
``` bash
cat << 'EOF' > backend.tf
terraform {
  backend "local" {
    path = "./mybackend.tfstate"
  }
}
EOF
```

If we try to run a terraform plan we get an error, because changes in the backend config require an init again.
``` bash
terraform plan
```

```
╷
│ Error: Backend initialization required, please run "terraform init"
│
│ Reason: Initial configuration of the requested backend "local"
│
│ The "backend" is the interface that Terraform uses to store state,
│ perform operations, etc. If this message is showing up, it means that the
│ Terraform configuration you're using is using a custom configuration for
│ the Terraform backend.
│
│ Changes to backend configurations require reinitialization. This allows
│ Terraform to set up the new configuration, copy existing state, etc. Please run
│ "terraform init" with either the "-reconfigure" or "-migrate-state" flags to
│ use the current configuration.
│
│ If the change reason above is incorrect, please verify your configuration
│ hasn't changed and try again. At this point, no changes to your existing
│ configuration or state have been made.
╵
```

If we run Terraform init, we get asked, if we want to copy the state. Which we want, so we need to write yes.
``` bash
terraform init
```

```
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "local" backend. No existing state was found in the newly
  configured "local" backend. Do you want to copy this state to the new "local"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value:
```

Now we have a new file, mybackend.tfstate which contains the state information.
``` bash
ls
```

Why did we need the reconfigure? The reconfigure was needed for Terraform to create a new file in which the backend config is saved.
``` bash
cat .terraform/terraform.tfstate
```

This can also be done with a file
``` bash
cat << 'EOF' > backend.tfbackend
path = "./fromfile.tfstate"
EOF
```

We need to run it first one time with the -reconfigure option, so that Terraform saves the new infos about the backend.
``` bash
terraform init -reconfigure -backend-config=backend.tfbackend
```

```
Initializing the backend...

Successfully configured the backend "local"! Terraform will automatically
use this backend unless the backend configuration changes.
```

Now Terraform has the new config in place.
``` bash
cat .terraform/terraform.tfstate 
```

```
{
  "version": 3,
  "terraform_version": "1.11.2",
  "backend": {
    "type": "local",
    "config": {
      "path": "./fromfile.tfstate",
      "workspace_dir": null
    },
    "hash": 3472824800
  }
```

But if we run an ls we can't see the fromfile.tfstate. That is because we only reconfigured the backend and didn't migrate it. 
``` bash
ls
```

So the terraform plan tries to create the resource again.
``` bash
terraform plan
```

```

Plan: 1 to add, 0 to change, 0 to destroy.
```

There is a specific command which allows migrating the local state to the cloud. In our case we only switched the naming for the local backend so we need to do it in a different way. The easiest way is just copping the file.
``` bash
cp mybackend.tfstate fromfile.tfstate
```

Now everything works like expected.
``` bash
terraform plan
```

```
local_file.generated: Refreshing state... [id=2ee5d2acea249b250d0c5886f5016929abd6d1b7]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes   
are needed.
```

Previously we used a file for configuring the backend and passed this file via a CLI option. The whole config can also be done directly with CLI options. For this the single key value pairs can be passed via the backend-config. 
``` bash
terraform init -backend-config="path=./fromfile.tfstate"
```

``` bash
terraform init -migrate-state -backend-config=backend.tfbackend
```

### Working with remote state

!!! For the backend use the following vars
```
resource_group_name  = "kurs1"
storage_account_name = "newelements0123"
container_name       = "terraform"
# here set your name for the tfstate
key                  = "prod/<custom>.tfstate"
```

Have a local state is not ideal for working in a team, so for that we can use the remote state. For this we need an Azure Storage Account

For the config we have three options:
1. backend block
``` bash
cat << 'EOF' > backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "kurs1"
    storage_account_name = "newelements0123"
    container_name       = "terraform"
    key                  = "prod/<custom>.tfstate"
  }
}
EOF
```
2. CLI options
``` bash
terraform init \
  -backend-config="resource_group_name=..." \
  -backend-config="storage_account_name=..." \
  -backend-config="container_name=..." \
  -backend-config="key=..." \
```
3. Backend config file
``` bash
cat << 'EOF' > backend.tfbackend
resource_group_name  = ""
storage_account_name = ""
container_name       = ""
key                  = "prod/infrastructure.tfstate"
EOF
```

```  bash
terraform init -backend-config=./backend.tfbackend
```

If we selected a method, we can now start with the init process.
1. First we need to set the auth against the remote backend. Here Azure.
``` bash
export ARM_CLIENT_ID=""
export ARM_CLIENT_SECRET=""
export ARM_TENANT_ID=""
export ARM_SUBSCRIPTION_ID=""
```
2. Now we can try to migrate the state
``` bash
terraform init -migrate-state
```

If permissions are missing we get the following error:
```
unexpected status 403 (403 Forbidden) with error: AuthorizationFailed: The client 'aeade839-4b81-488d-8d60-de50d12069ab' with object id 'cfb54a13-d154-42b8-bbb8-86e020153438' does not have authorization to perform action 'Microsoft.Storage/storageAccounts/read' over scope '/subscriptions/b839dba6-c92d-4975-8ea0-ec65addc6677/resourceGroups/dominiklandaude/providers/Microsoft.Storage/storageAccounts/dominiklandau' or the scope is invalid. If access was recently granted, please refresh your credentials.
```

Two roles are needed: 
- Storage Blob Data Contributor
- Storage Account Contributor

If successful
```
Initializing the backend...
Terraform detected that the backend type changed from "local" to "azurerm".

Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "azurerm" backend. No existing state was found in the newly
  configured "azurerm" backend. Do you want to copy this state to the new "azurerm"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes


Successfully configured the backend "azurerm"! Terraform will automatically
use this backend unless the backend configuration changes.
```

3. Check if everything works
``` bash
terraform plan
```

```
local_file.generated: Refreshing state... [id=2ee5d2acea249b250d0c5886f5016929abd6d1b7]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes   
are needed.
```
