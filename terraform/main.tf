terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "packer_images" {
  name     = "packer-images"
  location = "UK South"
}

resource "azurerm_resource_group" "devops_academy" {
  name     = "devops-academy"
  location = "UK South"
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

  security_rule {
    name                       = "http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ssh"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "nc-img"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5555"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "nc-msg"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5556"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "empty"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5557"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "empty-deny"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5558"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ICMP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "ICMP"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "all"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
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
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.demo_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = data.azurerm_image.base_image.id

}

data "azurerm_image" "base_image" {
  name                = "ubuntu-mixed-server-0.0.3"
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
  value = "nc ${azurerm_linux_virtual_machine.demo_machine.public_ip_address} 5555 > image.jpg"
}

output "get_message" {
  value = "nc ${azurerm_linux_virtual_machine.demo_machine.public_ip_address} 5556"
}