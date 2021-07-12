variable "image_version" {
  default = "1.0.0"
}

variable "image_name" {
  default = "ubuntu-mixed-server"
}

variable "base_image_name" {
  default = "ubuntu-base-1.0.0"
}

source "amazon-ebs" "image" {
  ami_name      = "${var.image_name}-${var.image_version}"
  instance_type = "t2.micro"
  region        = "eu-west-2"
  source_ami_filter {
    filters = {
      name                = "${var.base_image_name}"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["self"]
  }
  ssh_username = "ubuntu"

  tags = {
      owner = "packer"
  }
}

source "azure-arm" "image" {
  use_azure_cli_auth = true

  os_type = "Linux"

  custom_managed_image_name = "${var.base_image_name}"
  custom_managed_image_resource_group_name = "packer-images"

  managed_image_resource_group_name = "packer-images"
  managed_image_name = "${var.image_name}-${var.image_version}"
  
  azure_tags = {
    owner = "packer"
  }

  location = "UK South"
  vm_size = "Standard_DS2_v2"
}

build {
  sources = ["sources.azure-arm.image", "sources.amazon-ebs.image"]

  provisioner "shell" {
    inline = ["echo Connected via SSM at '${build.User}@${build.Host}:${build.Port}'"]
  }

  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "apt-get install software-properties-common -y",
      "apt-add-repository --yes ppa:ansible/ansible",
      "apt-get update",
      "apt-get install ansible -y"
    ]
  }

  provisioner "ansible-local" {
    playbook_dir = "../common/ansible/"
    playbook_file   = "../common/ansible/configure-server.yml"
    extra_arguments = [
        "--tags='web, netcat'",
        "--extra-vars 'ansible_sudo_pass=packer'"
      ]
  }

  provisioner "shell" {
    execute_command = "echo 'packer' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script = "../common/scripts/clean-up.sh"
  }

  provisioner "shell" {
    only = ["azure-arm.image"]
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
          "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
    inline_shebang = "/bin/sh -x"
  }
}