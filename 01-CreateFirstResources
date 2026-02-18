## Download Terraform

https://developer.hashicorp.com/terraform/install#linux

``` bash
sudo apt install unzip

curl -LO https://releases.hashicorp.com/terraform/1.14.5/terraform_1.14.5_linux_amd64.zip
unzip terraform_1.14.5_linux_amd64.zip

sudo install -m 755 terraform /usr/bin
```

Check if everything is installed
``` bash
which terraform
```

``` bash
terraform version
```
### Basics

``` bash
mkdir ~/01 && cd ~/01
```

In this step we use the local provider.
https://registry.terraform.io/providers/hashicorp/local/latest/docs

Create a first file (main.tf) with a single resource
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

``` bash
terraform plan
```
	Here we get an error - We need to initialize it first

Error message:
```
╷ 
│ Error: Inconsistent dependency lock file 
│
│ The following dependency selections recorded in the lock file are inconsistent with the current configuration:                  
│   - provider registry.terraform.io/hashicorp/local: required by this configuration but no version is selected                     
│
│ To make the initial dependency selections that will initialize the dependency lock file, run:                                    
│   terraform init                                                ╵
```


``` bash
terraform init
```
	It downloaded some stuff
	
Download message:
```
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/local...
- Installing hashicorp/local v2.6.2...
- Installed hashicorp/local v2.6.2 (signed by HashiCorp)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```


Now we list all the files in our folder.
``` bash
ls -la
```
	There should be:
		main.tf
		.terraform
		.terraform.lock.hcl

Go down to the right provider and look at the downloaded content.
``` bash
ls .terraform/providers/registry.terraform.io/hashicorp/local/
```

#### Terraform provider
The provider and terraform config doesn't need to be present for simple scenarios, but it is always good to include them.

https://registry.terraform.io/providers/hashicorp/local/latest/docs
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

Now if we run the plan we should see the creation of a single object.
``` bash
terraform plan
```

```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.generated will be created
  + resource "local_file" "generated" {
      + content              = <<-EOT
            Hello from Terraform
        EOT
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0644"
      + filename             = "./generated.txt"
      + id                   = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

Now we tell Terraform to create the object.
``` bash
terraform apply
```
	Type: yes. 

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

local_file.generated: Creating...
local_file.generated: Creation complete after 0s [id=2ee5d2acea249b250d0c5886f5016929abd6d1b7]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

``` bash
ls
```
	Now there should be two more files generated.txt and terraform.tfstate

If we run the plan again, Terraform tells us everything is already there
``` bash
terraform plan
```

```
local_file.generated: Refreshing state... [id=2ee5d2acea249b250d0c5886f5016929abd6d1b7]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```

#### Modify the generated file

``` bash
echo "more data" >> generated.txt
```

Now the plan shows that the already existing object changed and needs to be recreated.
``` bash
terraform plan
```

```
local_file.generated: Refreshing state... [id=2ee5d2acea249b250d0c5886f5016929abd6d1b7]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.generated will be created
  + resource "local_file" "generated" {
      + content              = <<-EOT
            Hello from Terraform
        EOT
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0644"
      + filename             = "./generated.txt"
      + id                   = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

Now apply the changes
``` bash
terraform apply -auto-approve
```

```
Plan: 1 to add, 0 to change, 0 to destroy.
local_file.generated: Creating...
local_file.generated: Creation complete after 0s [id=2ee5d2acea249b250d0c5886f5016929abd6d1b7]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

#### tf state file

Analyse the tfstate file
``` bash
cat terraform.tfstate | less
```

List all the resources in the tf state
``` bash
terraform state list
```

```
local_file.generated
```

Analyse the one resource in the state file
```
terraform state show local_file.generated
```

```
# local_file.generated:
resource "local_file" "generated" {
    content              = <<-EOT
        Hello from Terraform
    EOT
    content_base64sha256 = "IqBLfRwOUQN7HJwOD9wkP5aYGVSFYOHa8qi2LZz+OPc="
    content_base64sha512 = "xb4mOvwXK/4IgkIdf9RKeIXP0766mT+tXnmgRLXVUAJ1hewbs65AwxTUcqVsNLuWVKA5daQ2wzWgwkB3j7Y5Ww=="
    content_md5          = "a1a47e3cb3032413a5e0c8d70113a312"
    content_sha1         = "2ee5d2acea249b250d0c5886f5016929abd6d1b7"
    content_sha256       = "22a04b7d1c0e51037b1c9c0e0fdc243f969819548560e1daf2a8b62d9cfe38f7"
    content_sha512       = "c5be263afc172bfe0882421d7fd44a7885cfd3beba993fad5e79a044b5d550027585ec1bb3ae40c314d472a56c34bb9654a03975a436c335a0c240778fb6395b"
    directory_permission = "0777"
    file_permission      = "0644"
    filename             = "./generated.txt"
    id                   = "2ee5d2acea249b250d0c5886f5016929abd6d1b7"
}
```

