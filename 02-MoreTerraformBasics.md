### Read existing resources

Switch back to the previous folder

``` bash
cd ~/01
```

Create a new file with some data
``` bash
echo "Some data" > existing.txt
```

Now read the newly created file with a Terraform Data-Block
``` bash
cat << 'EOF' > data.tf
# Read an existing file with a data block
data "local_file" "existing" {
  filename = "${path.module}/existing.txt"
}
EOF
```

Now check if everything works
``` bash
terraform plan
```
	If you look at the output of the terraform plan, there sould be a line with 'data.local_file.exisiting: Read Complete'

```
local_file.generated: Refreshing state... [id=2ee5d2acea249b250d0c5886f5016929abd6d1b7]
data.local_file.existing: Reading...
data.local_file.existing: Read complete after 0s [id=9d786886aee9e694b73a9459e7b05bae03d1cb1c]
```
### Create Output
After working with the Data-Block, we now create some output. For this we use the previously read content of the Data-Block.
``` bash
cat << 'EOF' > output.tf
# Show content of the existing file
output "existing_file_content" {
  value = data.local_file.existing.content
}
EOF
```

With the plan command we can now see that the content of the file will be added as Output.
``` bash
terraform plan
```

```
data.local_file.existing: Reading...
local_file.generated: Refreshing state... [id=2ee5d2acea249b250d0c5886f5016929abd6d1b7]
data.local_file.existing: Read complete after 0s [id=9d786886aee9e694b73a9459e7b05bae03d1cb1c]

Changes to Outputs:
  + existing_file_content = <<-EOT
        Some data
    EOT

```

``` bash
terraform apply
```
	Now there is a new line with 'Outputs:'

Terraform has a specific command for showing the available outputs.
``` bash
terraform output
```

```
existing_file_content = <<EOT
Some data

EOT
```

The output above is a little bit verbose, but we can reduce it with the command below
``` bash
terraform output -raw existing_file_content
```

```
some data
```

Like with the resources Terraform also saves all the outputs in the terraform.tfstate file. With the command below, you can see in the first few lines, that the output is saved
``` bash
cat terraform.tfstate | less
```

```
{
  "version": 4,
  "terraform_version": "1.14.5",
  "serial": 2,
  "lineage": "c72be1fa-9416-7be0-62e0-a91fbb3d10d8",
  "outputs": {
    "existing_file_content": {
      "value": "Some data\n",
      "type": "string"
    }
  },
  ...
```
### Variables
The current setup is quiet static and has only hard coded values. In an production environment you often want the ability to dynamically add resources based on some value. For this we use the variables.

Here is a simple example for creating a variable and use the variable in a resource block.
``` bash
cat << 'EOF' > vars.tf
variable "content" {
  description = "Content to write into the file"
  type        = string
  default     = "Hello from Terraform\n"
}

resource "local_file" "variable" {
  filename        = "${path.module}/variable.txt"
  content         = var.content
  file_permission = "0644"
}
EOF
```

With the Terraform plan we can now see, that there is a new file generated with the content of the default from the variable.
``` bash
terraform plan
```

```
Terraform will perform the following actions:

  # local_file.variable will be created
  + resource "local_file" "variable" {
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
      + filename             = "./variable.txt"
      + id                   = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

Now we can create the new resource.
``` bash
terraform apply
```

If we run the plan again, we see that Terraform doesn't need to 
``` bash
terraform plan
```

#### Pass variable via command line
To change the content of the resource we will pass a new value for the variable.
``` bash
terraform plan -var=content=test
```

Here a replacement is triggered because of the changes to the content of the file.
```
# local_file.variable must be replaced
-/+ resource "local_file" "variable" {
      ~ content              = <<-EOT # forces replacement
          - Hello from Terraform
          + test
        EOT
      ~ content_base64sha256 = "IqBLfRwOUQN7HJwOD9wkP5aYGVSFYOHa8qi2LZz+OPc=" -> (known after apply)
      ~ content_base64sha512 = "xb4mOvwXK/4IgkIdf9RKeIXP0766mT+tXnmgRLXVUAJ1hewbs65AwxTUcqVsNLuWVKA5daQ2wzWgwkB3j7Y5Ww==" -> (known after apply)
      ~ content_md5          = "a1a47e3cb3032413a5e0c8d70113a312" -> (known after apply)
      ~ content_sha1         = "2ee5d2acea249b250d0c5886f5016929abd6d1b7" -> (known after apply)
      ~ content_sha256       = "22a04b7d1c0e51037b1c9c0e0fdc243f969819548560e1daf2a8b62d9cfe38f7" -> (known after apply)
      ~ content_sha512       = "c5be263afc172bfe0882421d7fd44a7885cfd3beba993fad5e79a044b5d550027585ec1bb3ae40c314d472a56c34bb9654a03975a436c335a0c240778fb6395b" -> (known after apply)
      ~ id                   = "2ee5d2acea249b250d0c5886f5016929abd6d1b7" -> (known after apply)
        # (3 unchanged attributes hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

``` bash
terraform apply -var=content=test
```

```
local_file.variable: Destroying... [id=2ee5d2acea249b250d0c5886f5016929abd6d1b7]
local_file.variable: Destruction complete after 0s
local_file.variable: Creating...
local_file.variable: Creation complete after 0s [id=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```

Now everything is up-to-date.
``` bash
terraform plan
```

#### Env vars
An other way to change the value of the variable we can use the environment variables. Here we need to get the name of the variable and set "TF_VAR_" as a prefix.
``` bash
export TF_VAR_content="From env"
```

Now we see changes to the resource.
``` bash
terraform plan
```

```
  # local_file.variable must be replaced
-/+ resource "local_file" "variable" {
      ~ content              = "test" -> "From env" # forces replacement
      ~ content_base64sha256 = "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=" -> (known after apply)
      ~ content_base64sha512 = "7iaw3Ur350mqGo7jwQrpkj9hiYB3Lkc/iBml1JQODbJ6wYX4oOHV+E+IvIh/1nsUNzLDBMxfqa2Ob1f1ACio/w==" -> (known after apply)
      ~ content_md5          = "098f6bcd4621d373cade4e832627b4f6" -> (known after apply)
      ~ content_sha1         = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3" -> (known after apply)
      ~ content_sha256       = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08" -> (known after apply)
      ~ content_sha512       = "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff" -> (known after apply)
      ~ id                   = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3" -> (known after apply)
        # (3 unchanged attributes hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

``` bash
terraform apply -auto-approve
```

```
  # local_file.variable must be replaced
-/+ resource "local_file" "variable" {
      ~ content              = "test" -> "From env" # forces replacement
      ~ content_base64sha256 = "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=" -> (known after apply)
      ~ content_base64sha512 = "7iaw3Ur350mqGo7jwQrpkj9hiYB3Lkc/iBml1JQODbJ6wYX4oOHV+E+IvIh/1nsUNzLDBMxfqa2Ob1f1ACio/w==" -> (known after apply)
      ~ content_md5          = "098f6bcd4621d373cade4e832627b4f6" -> (known after apply)
      ~ content_sha1         = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3" -> (known after apply)
      ~ content_sha256       = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08" -> (known after apply)
      ~ content_sha512       = "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff" -> (known after apply)
      ~ id                   = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3" -> (known after apply)
        # (3 unchanged attributes hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.
local_file.variable: Destroying... [id=a94a8fe5ccb19ba61c4c0873d391e987982fbbd3]
local_file.variable: Destruction complete after 0s
local_file.variable: Creating...
local_file.variable: Creation complete after 0s [id=0230a3253e42cd03ed1b9e6377ab91b3d8c9708f]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```

Now the infrastructure is up-to-date
``` bash
terraform plan
```

```
local_file.variable: Refreshing state... [id=0230a3253e42cd03ed1b9e6377ab91b3d8c9708f]
local_file.generated: Refreshing state... [id=2ee5d2acea249b250d0c5886f5016929abd6d1b7]
data.local_file.existing: Reading...
data.local_file.existing: Read complete after 0s [id=9d786886aee9e694b73a9459e7b05bae03d1cb1c]

No changes. Your infrastructure matches the configuration.
```
#### tfvars
The last way to change the variable is via a tfvars file. This is just a simple text file which contains the variables and its values. By default terraform will look for a file terraform.tfvars, if you want to use a different name the file needs to be passed with the argument -var-file.

Here we use the default name for it.
``` bash
cat << 'EOF' > terraform.tfvars
content = "from tfvars"
EOF
```

Now the plan want to recreate the object based on the value of the terraform.tfvars file.
``` bash
terraform plan
```

```
  # local_file.variable must be replaced
-/+ resource "local_file" "variable" {
      ~ content              = "From env" -> "from tfvars" # forces replacement
      ~ content_base64sha256 = "6oNR16UQY0cLTlnl/1vTNqOHy8EPF0ZDK5PuhzjGlJo=" -> (known after apply)
      ~ content_base64sha512 = "OkXnJbji2GA/eIuFl6CIFa/Y+Y8CPViYjSxKw2GDe28oGzQmE2KGia5R6OGJ0KFKlhtZVq29/YbJix5Y2hiNhw==" -> (known after apply)
      ~ content_md5          = "19c65d6b7851dd0f08d277176bf470be" -> (known after apply)
      ~ content_sha1         = "0230a3253e42cd03ed1b9e6377ab91b3d8c9708f" -> (known after apply)
      ~ content_sha256       = "ea8351d7a51063470b4e59e5ff5bd336a387cbc10f1746432b93ee8738c6949a" -> (known after apply)
      ~ content_sha512       = "3a45e725b8e2d8603f788b8597a08815afd8f98f023d58988d2c4ac361837b6f281b342613628689ae51e8e189d0a14a961b5956adbdfd86c98b1e58da188d87" -> (known after apply)
      ~ id                   = "0230a3253e42cd03ed1b9e6377ab91b3d8c9708f" -> (known after apply)
        # (3 unchanged attributes hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```


``` bash
terraform apply
```

```
local_file.variable: Destroying... [id=0230a3253e42cd03ed1b9e6377ab91b3d8c9708f]
local_file.variable: Destruction complete after 0s
local_file.variable: Creating...
local_file.variable: Creation complete after 0s [id=2848bc2ad2f5d2e0323f7a8f4223e2e3e9f1bb9e]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```

``` bash
terraform plan
```

```
data.local_file.existing: Reading...
local_file.generated: Refreshing state... [id=2ee5d2acea249b250d0c5886f5016929abd6d1b7]
local_file.variable: Refreshing state... [id=2848bc2ad2f5d2e0323f7a8f4223e2e3e9f1bb9e]
data.local_file.existing: Read complete after 0s [id=9d786886aee9e694b73a9459e7b05bae03d1cb1c]

No changes. Your infrastructure matches the configuration.
```

#### tfvars with different name

Here we create a new tfvars file with different content.
``` bash
cat << 'EOF' > prod.tfvars
content = "for prod"
EOF
```

If we run the terraform plan, it wont do anything because it default to the terraform.tfvars.
```
terraform plan
```

To use a different tfvars file we need to pass it via the CLI argument -var-file.
``` bash
terraform plan -var-file=prod.tfvars
```

```
  # local_file.variable must be replaced
-/+ resource "local_file" "variable" {
      ~ content              = "from tfvars" -> "for prod" # forces replacement
      ~ content_base64sha256 = "xvnm+ziFmMpHe1rwRSAAKf7GwUR2zvL8BhymLyF1tYE=" -> (known after apply)
      ~ content_base64sha512 = "dVHHX5XAaMk7yUUMsUITHZ05OHLp/n5OCfxAMXgbDvgeSRF0L+xjBQTHniccXZl7ztEE2EneekkhXLYqQpPGqQ==" -> (known after apply)
      ~ content_md5          = "592958ccd972d187e1dd9a34cef6f0f9" -> (known after apply)
      ~ content_sha1         = "2848bc2ad2f5d2e0323f7a8f4223e2e3e9f1bb9e" -> (known after apply)
      ~ content_sha256       = "c6f9e6fb388598ca477b5af045200029fec6c14476cef2fc061ca62f2175b581" -> (known after apply)
      ~ content_sha512       = "7551c75f95c068c93bc9450cb142131d9d393872e9fe7e4e09fc4031781b0ef81e4911742fec630504c79e271c5d997bced104d849de7a49215cb62a4293c6a9" -> (known after apply)
      ~ id                   = "2848bc2ad2f5d2e0323f7a8f4223e2e3e9f1bb9e" -> (known after apply)
        # (3 unchanged attributes hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

``` bash
terraform apply -var-file=prod.tfvars
```

```
local_file.variable: Destroying... [id=2848bc2ad2f5d2e0323f7a8f4223e2e3e9f1bb9e]
local_file.variable: Destruction complete after 0s
local_file.variable: Creating...
local_file.variable: Creation complete after 0s [id=80e23a712a7e028f9948b2498aa2fda92cbf8ada]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```

Now everything is up-to-date.
``` bash
terraform plan -var-file=prod.tfvars
```

If we run the plan without the -var-file argument, then it will default to the terraform.tfvars file and tries to recreate the file.
``` bash
terraform plan
```

```
  # local_file.variable must be replaced
-/+ resource "local_file" "variable" {
      ~ content              = "for prod" -> "from tfvars" # forces replacement
      ~ content_base64sha256 = "JKuZaSaqIH4SDX9QKTTFjiUlcCoobwigrqZJwrVrk/U=" -> (known after apply)
      ~ content_base64sha512 = "eOo5Dn9q37sFbmKm+wZ7RGaZfStjB0rYmMv6/kII+XZu2Vift4EFyJUf/WoVE92aHVo/mGpkglw3yF6ru2VKtA==" -> (known after apply)
      ~ content_md5          = "dc9f7d414d4c8a2a1eb452bb85f1fc30" -> (known after apply)
      ~ content_sha1         = "80e23a712a7e028f9948b2498aa2fda92cbf8ada" -> (known after apply)
      ~ content_sha256       = "24ab996926aa207e120d7f502934c58e2525702a286f08a0aea649c2b56b93f5" -> (known after apply)
      ~ content_sha512       = "78ea390e7f6adfbb056e62a6fb067b4466997d2b63074ad898cbfafe4208f9766ed9589fb78105c8951ffd6a1513dd9a1d5a3f986a64825c37c85eabbb654ab4" -> (known after apply)
      ~ id                   = "80e23a712a7e028f9948b2498aa2fda92cbf8ada" -> (known after apply)
        # (3 unchanged attributes hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```
