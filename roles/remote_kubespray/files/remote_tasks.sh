
declare -a IPS=(192.168.10.11 192.168.10.12 192.168.10.13)

CONFIG_FILE=inventory/mycluster/hosts.yml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

ansible-playbook -i inventory/mycluster/hosts.yml --become --become-user=root cluster.yml

