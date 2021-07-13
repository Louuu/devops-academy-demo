build {
    sources = [...]

    provisioner "shell" {
        inline = ["whoami'"]
    }

    provisioner "shell" {
        script = "../common/scripts/install-ansible.sh"
    }

    provisioner "shell" {
        execute_command = "echo 'packer' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
        script = "../common/scripts/install-ansible.sh"
    }
}