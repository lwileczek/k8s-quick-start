# Barebones Deployment

This role deploys the bare bones components of Kubernetes to a cluster

## Assumptions

 - Passwordless sudo and ssh is setup to the machines
 - common playbook has already been run

## Deployment

Only Deploys Kubelet, Kubeadm, Kubectl and a network overlay: Flannel | Calico
