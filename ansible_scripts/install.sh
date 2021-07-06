#!/bin/bash
    
sudo apt update 
sudo apt install software-properties-common 
sudo add-apt-repository --yes --update ppa:ansible/ansible 
sudo apt install ansible
ansible-playbook ansible_scripts/ansible_install_MicroK8s_with_volume.yaml -i ansible_scripts/variables