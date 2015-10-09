#!/bin/bash
#
# Windows shell provisioner for Ansible playbooks based on geerlingguy's
# JJG-Ansible-Windows https://github.com/geerlingguy/JJG-Ansible-Windows

# Platbook path
ANSIBLE_PLAYBOOK=$1
# Resulting settings in JSON format; to be used as extra vars for ansible
ANSIBLE_EXTRA_VARS=$2

# Make sure Ansible playbook exists.
if [ ! -f /vagrant/$ANSIBLE_PLAYBOOK ]; then
  echo "Cannot find Ansible playbook."
  exit 1
fi

# Install Ansible and its dependencies if it's not installed already. Redirect
# stdout and stderr to /dev/null.
if [ ! -f /usr/bin/ansible ]; then
  echo "Installing Ansible on virtual machine."
  echo ""
  # Install required dependencies.
  apt-get -y install software-properties-common > /dev/null 2>&1
  # Add Ansible PPA.
  add-apt-repository ppa:ansible/ansible > /dev/null 2>&1
  # Update repositories.
  apt-get -y update > /dev/null 2>&1
  # Install Ansible.
  apt-get -y install ansible > /dev/null 2>&1
fi

# Run the playbook.
echo "Running Ansible provisioner defined in the Vagrantfile."
echo ""
ansible-playbook -i 'localhost,' -v /vagrant/${ANSIBLE_PLAYBOOK} --connection=local --extra-vars="${ANSIBLE_EXTRA_VARS}"
