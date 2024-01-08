#!/bin/bash
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt update -y
sudo apt install ansible -y
rm -rf .ssh/* || true
echo -e 'y' | ssh-keygen -t rsa -q -f '.ssh/id_rsa' -N ''
export RSYNC_RSH='ssh -o StrictHostKeyChecking=no'
cp .ssh/id_rsa.pub .ssh/authorized_keys
