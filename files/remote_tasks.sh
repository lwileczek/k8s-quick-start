#!/bin/bash


# deploy cluster
ansible-playbook -i inventory/mycluster/hosts.yml --become --become-user=root cluster.yml

# setup kubectl
chdir ~/

# change master_node_ip to
ssh {{ master_node_ip }} sudo cp /etc/kubernetes/admin.conf /home/{{ deploy_user }}/config
ssh {{ master_node_ip }} sudo chmod +r /home/{{ deploy_user }}/config
scp {{ master_node_ip }}:/home/{{ deploy_user }}/config .
mkdir .kube
mv config .kube
ssh {{ master_node_ip }} rm -r /home/{{ deploy_user }}/config

