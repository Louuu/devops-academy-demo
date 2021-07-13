terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "2.22.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "packer_images" {
  name     = "packer-images"
  location = var.location
}

resource "azurerm_resource_group" "devops_academy" {
  name     = "devops-academy"
  location = var.location
}

resource "azurerm_virtual_network" "devops_academy_network" {
  name                = "nw-devops-academy"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.devops_academy.location
  resource_group_name = azurerm_resource_group.devops_academy.name
}

resource "azurerm_subnet" "devops_academy_internal_sn" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.devops_academy.name
  virtual_network_name = azurerm_virtual_network.devops_academy_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "demo_nic" {
  name                = "demo-nic"
  location            = azurerm_resource_group.devops_academy.location
  resource_group_name = azurerm_resource_group.devops_academy.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops_academy_internal_sn.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo_public_ip.id
  }
}

resource "azurerm_public_ip" "demo_public_ip" {
  name                = "demoVMPublicIP"
  resource_group_name = azurerm_resource_group.devops_academy.name
  location            = azurerm_resource_group.devops_academy.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "demo_vm_nsg" {
  name                = "demoVMNetworkSecurityGroup"
  location            = azurerm_resource_group.devops_academy.location
  resource_group_name = azurerm_resource_group.devops_academy.name

  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.demo_nic.id
  network_security_group_id = azurerm_network_security_group.demo_vm_nsg.id
}

resource "azurerm_linux_virtual_machine" "demo_machine" {
  name                = "demo-machine"
  resource_group_name = azurerm_resource_group.devops_academy.name
  location            = azurerm_resource_group.devops_academy.location
  size                = "Standard_F2"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.demo_nic.id,
  ]

  custom_data = base64encode(templatefile("${path.module}/userdata/userdata.tpl", {
    gitlab_url = "${var.gitlab_url}", 
    gitlab_runner_token = "${var.gitlab_runner_token}",
    gitlab_runner_name = "${var.gitlab_runner_name}"
  }))

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = data.azurerm_image.base_image.id

}

data "azurerm_image" "base_image" {
  name                = "${var.image_name}-${var.image_version}"
  resource_group_name = azurerm_resource_group.packer_images.name
}

output "public_ip" {
  value = azurerm_linux_virtual_machine.demo_machine.public_ip_address
}

output "ssh" {
  value = "ssh ${azurerm_linux_virtual_machine.demo_machine.admin_username}@${azurerm_linux_virtual_machine.demo_machine.public_ip_address}"
}

output "http" {
  value = "http://${azurerm_linux_virtual_machine.demo_machine.public_ip_address}"
}

output "get_image" {
  value = "nc ${azurerm_linux_virtual_machine.demo_machine.public_ip_address} 5557 > image.jpg"
}

output "get_message" {
  value = "nc ${azurerm_linux_virtual_machine.demo_machine.public_ip_address} 5556"
}