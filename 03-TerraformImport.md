## Terraform import

An other important part of working with Terraform is importing already created resources into Terraform. In this example we use Docker for simplicity, so that we don't have to use external dependencies.

For Docker there is a community provider available which we will use:
https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs

``` bash
mkdir ~/02 && cd ~/02
```
### Install Docker
https://docs.docker.com/engine/install/debian/
First we need to add the Docker repository for Debian.
``` bash
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

After adding the Repo and running an apt update we can now install Docker onto the system.
``` bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

When Docker is installed it requires us to use sudo for executing commands. To be able to run Docker without sudo we need to add ourselfs to the Docker group. Which is done with the command below.
``` bash
sudo usermod -aG docker $USER
```

These changes to the our user are not instant for it to work we need to logout of the system and then login. After this the shell reloads and we are in the right group.

``` bash
id
```

### Setup example
First we need to create a provider config.
``` bash
cat << 'EOF' > provider.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}
EOF
```

Now we create some main.tf file which creates a two resources, read in a downloaded image and then creates an output.
``` bash
cat << 'EOF' > main.tf
# Pull and manage nginx image
resource "docker_image" "nginx" {
  name = "nginx:latest"
}

# Create and start nginx container
resource "docker_container" "nginx" {
  name  = "my-nginx"
  image = docker_image.nginx.image_id
  ports {
    internal = 80
    external = 8080
  }
}

# Data source: read existing container info
data "docker_image" "nginx_read" {
  name = docker_image.nginx.name
}

# Outputs
output "container_id" {
  value = docker_container.nginx.id
}
EOF
```

We created a new folder with completely new terraform code so we first need to initialise Terraform so that it downloads the appropriate files.
``` bash
terraform init
```

Run the terraform plan to see the changes
``` bash
terraform plan
```

```
Terraform will perform the following actions:

  # data.docker_image.nginx_read will be read during apply
  # (depends on a resource or a module with changes pending)
 <= data "docker_image" "nginx_read" {
      + id          = (known after apply)
      + name        = "nginx:latest"
      + repo_digest = (known after apply)
    }

  # docker_container.nginx will be created
  + resource "docker_container" "nginx" {
      + attach                                      = false
      ...
      + ports {
          + external = 8080
          + internal = 80
          + ip       = "0.0.0.0"
          + protocol = "tcp"
        }
    }

  # docker_image.nginx will be created
  + resource "docker_image" "nginx" {
      + id          = (known after apply)
      + image_id    = (known after apply)
      + name        = "nginx:latest"
      + repo_digest = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + container_id = (known after apply)
```

Now create the objects.
``` bash
terraform apply -auto-approve
```

```
docker_image.nginx: Creating...
docker_image.nginx: Still creating... [00m10s elapsed]
docker_image.nginx: Creation complete after 12s [id=sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208nginx:latest]
data.docker_image.nginx_read: Reading...
docker_container.nginx: Creating...
data.docker_image.nginx_read: Read complete after 0s [id=sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208]
docker_container.nginx: Creation complete after 6s [id=9170b85e7b10b468e79a6cf60de4aca8c72f092b8d060e9a7524aeacfc87c213]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

### Analyse the created objects

To import manually created object we first need to understand, how Terraform saves the information about them.

First we look at all the objects in the state
``` bash
terraform state list
```

Here we can see three objects.
```
data.docker_image.nginx_read
docker_container.nginx
docker_image.nginx
```

Now we can inspect these objects
```
terraform state show docker_image.nginx
```
The image object is quiet small with only four attributes.
```
# docker_image.nginx:
resource "docker_image" "nginx" {
    id          = "sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208nginx:latest"
    image_id    = "sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208"
    name        = "nginx:latest"
    repo_digest = "nginx@sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208"
}
```

The container resource on the other side has a lot more attributes.
```
terraform state show docker_container.nginx
```

```
# docker_container.nginx:
resource "docker_container" "nginx" {
    attach                                      = false
    bridge                                      = null
    command                                     = [
        "nginx",
        "-g",
        "daemon off;",
    ]
    container_read_refresh_timeout_milliseconds = 15000
    cpu_set                                     = null
    cpu_shares                                  = 0
    ...
    ports {
        external = 8080
        internal = 80
        ip       = "0.0.0.0"
        protocol = "tcp"
    }      
```

To import a resource we need three things. 
1. We need the Terraform config for the object
2. We need the path in the terraform state file
3. We need the id of the existing object

If these information is available we can use one of two options to import a resource.
1. terraform import \<path in state> \<resource id> (old way)
2. Terraform import block (new way)
### Import a manual created resource

To have a resource for importing we first need to create one. Here we start a simple container.
``` bash
docker run -d --name manual-nginx -p 8001:80 nginx:latest
```

With the container started we now the Terraform config for it. The config doesn't needs to be perfect, just a simple resource object. 
``` bash
cat << 'EOF' > manual.tf
resource "docker_container" "nginx2" {
  name  = "manual-nginx"
  image = docker_image.nginx.image_id
  ports {
    internal = 80
    external = 8001
  }
}
EOF
```

If we try a terraform plan it says, that a new resource will be created.
``` bash
terraform plan
```

Even if we try to apply the changes we get an error. So we now need to move to the import.
!!! Don't run such an apply in Production you can delete an existing resource!!!
```
terraform apply
```
	Error Container name already in use

To get an example for the import you can also reference the different resources in the provider, typically at the bottom you get the information.
https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container#import

##### Import with terraform import
The first import will be done with the terraform import command. Now we need to get the state path and container id.
``` bash
terraform import <state path> <container id>
```

To get the container id run the following command.
``` bash
docker inspect manual-nginx | grep "Id"
```

The output should look like the one below
```
c776ce59ee842253f46a11459139e94c5a8e006611ff029a9f99f613f9c84f00
```

The second parameter is the path in the state.  To get this we can either construct it ourselves or use the terraform plan and copy it from there
``` bash
terraform plan
```

```
Terraform will perform the following actions:

  # docker_container.nginx2 will be created
```

With these information we can now construct the import command and execute it.
``` bash
terraform import docker_container.nginx2 c776ce59ee842253f46a11459139e94c5a8e006611ff029a9f99f613f9c84f00
```

Now we have the resource in the state.
```
  Prepared docker_container for import
docker_container.nginx2: Refreshing state... [id=c776ce59ee842253f46a11459139e94c5a8e006611ff029a9f99f613f9c84f00]
data.docker_image.nginx_read: Reading...
data.docker_image.nginx_read: Read complete after 0s [id=sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.
```

Despite importing the resource we still need to do some fixes. 
``` bash
terraform plan
```

To see what we need to change inspect the output of the plan command and look at each line which has <b># forces replacement</b> at the end.
```
  # docker_container.nginx2 must be replaced
-/+ resource "docker_container" "nginx2" {
      + attach                                      = false
      + bridge                                      = (known after apply)
      ~ command                                     = [
          - "nginx",
          - "-g",
          - "daemon off;",
        ] -> (known after apply)
      + container_logs                              = (known after apply)
      + container_read_refresh_timeout_milliseconds = 15000
      - cpu_shares                                  = 0 -> null
      - dns                                         = [] -> null
      - dns_opts                                    = [] -> null
      - dns_search                                  = [] -> null
      ~ entrypoint                                  = [
          - "/docker-entrypoint.sh",
        ] -> (known after apply)
      + env                                         = (known after apply) # forces replacement
      + exit_code                                   = (known after apply)
      - group_add                                   = [] -> null
      ~ hostname                                    = "c776ce59ee84" -> (known after apply)
      ~ id                                          = "c776ce59ee842253f46a11459139e94c5a8e006611ff029a9f99f613f9c84f00" -> (known after apply)
      ~ image                                       = "nginx:latest" -> "sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208" # forces replacement
      ~ init                                        = false -> (known after apply)
      ~ ipc_mode                                    = "private" -> (known after apply)
      ~ log_driver                                  = "json-file" -> (known after apply)
      - log_opts                                    = {} -> null
      + logs                                        = false
      - max_retry_count                             = 0 -> null
      - memory                                      = 0 -> null
      - memory_swap                                 = 0 -> null
      + must_run                                    = true
        name                                        = "manual-nginx"
      ~ network_data                                = [
          - {
              - gateway                   = "172.18.0.1"
              - global_ipv6_prefix_length = 0
              - ip_address                = "172.18.0.3"
              - ip_prefix_length          = 16
              - mac_address               = "fe:34:71:28:dd:1d"
              - network_name              = "bridge"
                # (2 unchanged attributes hidden)
            },
        ] -> (known after apply)
      - privileged                                  = false -> null
      - publish_all_ports                           = false -> null
      + remove_volumes                              = true
      ~ runtime                                     = "runc" -> (known after apply)
      ~ security_opts                               = [] -> (known after apply)
      ~ shm_size                                    = 64 -> (known after apply)
      + start                                       = true
      ~ stop_signal                                 = "SIGQUIT" -> (known after apply)
      ~ stop_timeout                                = 0 -> (known after apply)
      - storage_opts                                = {} -> null
      - sysctls                                     = {} -> null
      - tmpfs                                       = {} -> null
      + wait                                        = false
      + wait_timeout                                = 60
        # (12 unchanged attributes hidden)

      ~ healthcheck (known after apply)

      ~ labels (known after apply)

      - ports { # forces replacement
          - external = 8001 -> null
          - internal = 80 -> null # forces replacement
          - ip       = "::" -> null # forces replacement
          - protocol = "tcp" -> null
        }

        # (1 unchanged block hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

With the information from above we can construct a better resource config. So now we use the one blow.
``` bash
cat << 'EOF' > manual.tf
resource "docker_container" "nginx2" {
  name  = "manual-nginx"
  image = "nginx:latest"
  
  env = []
  ports {
    internal = 80
    external = 8001
    ip = "0.0.0.0"
    protocol = "tcp"
  }
  
  ports {
    internal = 80
    external = 8001
    ip = "::"
    protocol = "tcp"
  }
}
EOF
```

To test if everything works now we 
``` bash
terraform plan
```

This looks better, now Terraform will only change the container and not recreate it.
```
  # docker_container.nginx2 will be updated in-place
  ~ resource "docker_container" "nginx2" {
      + attach                                      = false
      + container_read_refresh_timeout_milliseconds = 15000
        id                                          = "c776ce59ee842253f46a11459139e94c5a8e006611ff029a9f99f613f9c84f00"
      + logs                                        = false
      + must_run                                    = true
        name                                        = "manual-nginx"
      + remove_volumes                              = true
      + start                                       = true
      + wait                                        = false
      + wait_timeout                                = 60
        # (40 unchanged attributes hidden)

        # (2 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Now we can either add these missing attributes to the terraform config or use a the lifecycle block in the resource. For a better understanding we use the lifecycle block here.

We now modify out manual.tf file and add a lifecycle block which contains all the attributes from the plan with an "+" in the beginning.
``` bash
cat << 'EOF' > manual.tf
resource "docker_container" "nginx2" {
  name  = "manual-nginx"
  image = "nginx:latest"
  
  env = []
  ports {
    internal = 80
    external = 8001
    ip = "0.0.0.0"
    protocol = "tcp"
  }
  
  ports {
    internal = 80
    external = 8001
    ip = "::"
    protocol = "tcp"
  }
  
  lifecycle {
    ignore_changes = [
      attach,
      logs,
      must_run,
      start,
      wait,
      wait_timeout,
      remove_volumes,
      container_read_refresh_timeout_milliseconds
    ]
  }
}
EOF
```

Now we fixed it that no changes needs to be done.
```
terraform plan
```

```
docker_container.nginx2: Refreshing state... [id=c776ce59ee842253f46a11459139e94c5a8e006611ff029a9f99f613f9c84f00]
docker_image.nginx: Refreshing state... [id=sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208nginx:latest]
docker_container.nginx: Refreshing state... [id=9170b85e7b10b468e79a6cf60de4aca8c72f092b8d060e9a7524aeacfc87c213]
data.docker_image.nginx_read: Reading...
data.docker_image.nginx_read: Read complete after 0s [id=sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208]

No changes. Your infrastructure matches the configuration.
```

#### Import with import block
To test the second import option we need an other container. So run 
``` bash
docker run -d --name manual-nginx2 -p 8002:80 nginx:latest
```

First create the terraform config
``` bash
cat << 'EOF' > manual2.tf
resource "docker_container" "nginx3" {
  name  = "manual-nginx2"
  image = "nginx:latest"
  
  env = []
  ports {
    internal = 80
    external = 8002
    ip = "0.0.0.0"
    protocol = "tcp"
  }
  
  ports {
    internal = 80
    external = 8002
    ip = "::"
    protocol = "tcp"
  }
}
EOF
```

To get the container id run the following command.
``` bash
docker inspect manual-nginx | grep "Id"
```

To get the state path use the following command.
``` bash
terraform plan
```

Now for importing we use the import block. So we create a new file for it.
``` bash
cat << 'EOF' > import.tf
import {
  to   = docker_container.nginx3
  id   = "2f90e905306a9f307a47187948989e0eacd0fbdb33a9a04fe1fa2c73462961a2"
}
EOF
```

If we run the terraform plan, we can see, that the resource will be successfully imported.

``` bash
terraform plan
```

```
docker_container.nginx3: Preparing import... [id=2f90e905306a9f307a47187948989e0eacd0fbdb33a9a04fe1fa2c73462961a2]
docker_image.nginx: Refreshing state... [id=sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208nginx:latest]
docker_container.nginx2: Refreshing state... [id=c776ce59ee842253f46a11459139e94c5a8e006611ff029a9f99f613f9c84f00]
docker_container.nginx3: Refreshing state... [id=2f90e905306a9f307a47187948989e0eacd0fbdb33a9a04fe1fa2c73462961a2]
docker_container.nginx: Refreshing state... [id=9170b85e7b10b468e79a6cf60de4aca8c72f092b8d060e9a7524aeacfc87c213]
data.docker_image.nginx_read: Reading...
data.docker_image.nginx_read: Read complete after 0s [id=sha256:341bf0f3ce6c5277d6002cf6e1fb0319fa4252add24ab6a0e262e0056d313208]
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  ~ update in-place
  
...
Plan: 1 to import, 0 to add, 1 to change, 0 to destroy.
```

Now we can apply it
``` bash
terraform apply
```

```
Plan: 1 to import, 0 to add, 1 to change, 0 to destroy.
docker_container.nginx3: Importing... [id=2f90e905306a9f307a47187948989e0eacd0fbdb33a9a04fe1fa2c73462961a2]
docker_container.nginx3: Import complete [id=2f90e905306a9f307a47187948989e0eacd0fbdb33a9a04fe1fa2c73462961a2]
docker_container.nginx3: Modifying... [id=2f90e905306a9f307a47187948989e0eacd0fbdb33a9a04fe1fa2c73462961a2]
docker_container.nginx3: Modifications complete after 0s [id=2f90e905306a9f307a47187948989e0eacd0fbdb33a9a04fe1fa2c73462961a2]

Apply complete! Resources: 1 imported, 0 added, 1 changed, 0 destroyed.
```
