#!/bin/bash -eux

echo "Creating the build directory"
mkdir -p /build/ansible

echo "Setting permissions on build directory"
chown -R packer:packer /build

echo "Installing ansible and requirements"
apt update
apt install software-properties-common -y
add-apt-repository --yes --update ppa:ansible/ansible
apt install ansible -y
