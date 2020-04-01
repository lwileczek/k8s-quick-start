#!/bin/bash

chdir ~/kubespray

declare -a IPS=( )  # add in the ips here for each node in your cluster
CONFIG_FILE=inventory/mycluster/hosts.yml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

# change deploy user
echo '## User defined user on remote hosts
ansible_user: {{ deploy_user }}
ansible_connection: ssh
ansible_python_interpreter: /usr/bin/python3' >> inventory/mycluster/group_vars/all/all.yml

# deploy cluster
ansible-playbook -i inventory/mycluster/hosts.yml --become --become-user=root cluster.yml

# setup kubectl
chdir ~/

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl

chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

# change master_node_ip to
ssh {{ master_node_ip }} sudo cp /etc/kubernetes/admin.conf /home/{{ deploy_user }}/config
ssh {{ master_node_ip }} sudo chmod +r /home/{{ deploy_user }}/config
scp {{ master_node_ip }}:/home/{{ deploy_user }}/config .
mkdir .kube
mv config .kube
ssh {{ master_node_ip }} rm -r /home/{{ deploy_user }}/config

