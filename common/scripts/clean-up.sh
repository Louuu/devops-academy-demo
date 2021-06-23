#!/bin/bash -eux

echo "Clearing up the ansible build directory"
[ -d "/build/ansible" ] && rm -fr "/build/ansible"

echo "Uninstalling Ansible"
apt remove ansible -y