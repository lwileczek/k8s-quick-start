# k8s-quick-start
Use Kubespary to set up a kubernetes cluster quickly

## Overview

Setup a Linux box that will act as the controller for the cluster.  From there
we'll download and launch kubespray.  It's advised that kubespray is downloaded
where ansible is not already installed.

### Kubespray

This is currently mapped to the [Kubspray](https://kubespray.io/#/) version 2.1.12

### Why Remote Controller

Switching work stations can be annoying and I want an idempotent setup that I
don't need to remember.  This should set up remote controller in the cloud with
3Gb transfer speeds (or more) accessible from anywhere with internet connection.

## Controller Server Tasks
Once you SSH to the controller server

```sh
cp -rfp inventory/sampel inventory/mycluster
declare -a IPS=(...)
CONFIG_FILE=inventory/mycluster/hosts.yml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```

In the `IPS` varialbe, you'll need to put all the IPs of your cluster.  This
script will store those in a file named `ip_list` in the home directory of the
controller server.

I had to add the following to `inventory/mycluster/group_vars/all/all.yml`.  for
example, if your `{{ deploy_user}}` was named "skeletor"

```yml
## User defined user on remote hosts
ansible_user: skeletor
ansible_connection: ssh
ansible_python_interpreter: /usr/bin/python3
```

Then you can start deploying kubespray by running
 
```sh
$ ansible-playbook -i inventory/mycluster/hosts.yml --become --become-user=root cluster.yml
```
### Kubectl

After the cluster is deployed, you will still want to manage the cluster from
the controller node.  To do this install [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) with

```sh
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
```
Then you want to make the binary exacutable and in your path so you can call it
from anywhere

```shell
$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
```

and then get the `.kube` file from one of the master nodes. 

```shell
$ ssh {{ master_node_ip }} sudo cp /etc/kubernetes/admin.conf /home/{{ deploy_user }}/config
$ ssh {{ master_node_ip }} sudo chmod +r /home/{{ deploy_user }}/config
$ scp {{ master_node_ip }}:/home/{{ deploy_user }}/config .
$ mkdir .kube
$ mv config .kube
$ ssh {{ master_node_ip }} rm -r /home/{{ deploy_user }}/config
```
Make sure to fill in `master_node_ip` and `deploy_user` with your specific
information.  Now you can test to make sure it's working with `$ kubectl get nodes` or 
`kubectl -n kube-system get pods`
