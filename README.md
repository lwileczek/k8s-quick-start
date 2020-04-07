# k8s-quick-start
Use Kubespary to set up a kubernetes cluster quickly

## Overview

Setup a Linux box that will act as the controller for the cluster.  From there
we'll download and launch kubespray.  It's advised that kubespray is downloaded
where ansible is not already installed.

### Requirements
This repository works on a debian or ubuntu controller and cluster of servers.
You'll need a cluster setup with access to the internet and which you can SSH
into. You should have 1 controller and at least three nodes.

### Kubespray

[Kubspray](https://kubespray.io/#/) is a collection of ansible scripts to make
it easier to deploy kubernetes.  Kubespray sets up templates as well which make
it easy to customize your deployment to your needs.  As of now, the kubespray
branchs map to these versions of kubernetes:

  - kubespray 2.1.12 => kubernetes 1.16.8
  - kubespray 2.1.11 => kubernetes 1.15.11
  - kubespray 2.1.10 => kubernetes 1.14.6
  - kubespray 2.1.9  => kubernetes 1.13.5

This can be found and changed in the file:
`kubespray/inventory/sample/group_vars/k8s-cluster/k8s-cluster.yml`
That being said, the version of other tools are configured to work together
withing kubespray, so it's probably better to use the corresponding version of
kubespray rather than change the value yourself, e.g. use kuberspray 2.1.12 &
kubernetes 1.14.

### Why Remote Controller

Switching work stations can be annoying and I want an idempotent setup that I
don't need to remember.  This should set up remote controller in the cloud with
3Gb transfer speeds (or more) accessible from anywhere with internet connection.

## Controller Server Tasks
Once you SSH to the controller server

Then you can start deploying kubespray by running
 
```sh
$ ansible-playbook -i inventory/mycluster/hosts.yml --become --become-user=root cluster.yml
```
### Kubectl

To control the cluster you'll need to make the `.kube` directory and get the `/etc/kubernetes/admin.conf` file from 
one of the master nodes.  You can do this by running `get_config.sh` on the
contoller server which will perform the following commands:

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


