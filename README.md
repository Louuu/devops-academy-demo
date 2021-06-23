# Packer Azure

A sample Packer Repository to create images in Microsoft Azure in a resource group named `packer-images`.

THIS README IS INCOMPLETE

## Requirements

- Terraform (Optional)
- Packer
- Azure CLI
- Microsoft Azure Subscription

## Directory Structure
```
.
├── README.md
├── terraform
│   └── main.tf
├── ubuntu-base
│   └── main.json
└── ubuntu-web-server
    └── main.json
```

### terraform
This is the Terraform code that spins up the resource group called packer-images

### ubuntu-base
This is a base image, normally this is the source for all other images. Install pieces of software here that need to be on all images.

### ubuntu-web-server
This is a simple nginx server that is built on top of `ubuntu-base`. Therefore `ubuntu-base` needs to be built first. When this image is deployed, you should be able to see a simple welcome message on port 80.

### ubuntu-mixed-server
This is a server that is built on top of `ubuntu-base`. It contains a web server and some netcat listeners on port 5555 and 5556.


## Setting up Resource Group

Ensure you're logged into the Azure CLI first

```
terraform init
terraform plan -target azurerm_resource_group.packer_images
terraform apply -target azurerm_resource_group.packer_images
```

## Usage
Ensure you're logged into the Azure CLI first

Replace ubuntu-base with the directory for the image you want to build.

```
cd ubuntu-base 
packer build main.json
```

## Improvements
Have a look at https://www.packer.io/docs/provisioners to learn more about the types of provisioners in use. 

Maybe break down some of the installation steps into individual scripts, copy some of your own files etc. Even create some of your own images.

Have a look to see if there is any way you can make some of the variables standardised, maybe create a script that starts off the build and reads important configuration from a json file and passes them as variables. For example:
- Base Image Name
- Base Image Version
- Current Image Name
- Current Image Version
- Default Resource Group

After creating a build script, you could then attempt to convert it into a pipeline using something like Azure DevOps