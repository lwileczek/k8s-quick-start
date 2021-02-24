#!/bin/bash
# Install Kubernetes inside a CentOS container
# Works for both Master and Worker nodes based off of the name of the container.
# Need at least one master and one worker to have a functioning cluster.
# Suggested using at least one master and two workers for testing purposes. 
#
# Taken From: 
#   User: justmeandopensource
#   Repo: https://github.com/justmeandopensource/kubernetes/blob/master/lxd-provisioning/bootstrap-kube.sh
#
# Example:
#   $ lxc list
#   +----------+---------+----------------------+-----------------------------------------------+------------+-----------+
#   |   NAME   |  STATE  |         IPV4         |                     IPV6                      |    TYPE    | SNAPSHOTS |
#   +----------+---------+----------------------+-----------------------------------------------+------------+-----------+
#   | kmaster  | RUNNING | 172.18.74.67 (eth0)  | fd42:1a11:f361:fc2f:216:3eff:fe57:9bbe (eth0) | PERSISTENT | 0         |
#   +----------+---------+----------------------+-----------------------------------------------+------------+-----------+
#   | kworker0 | RUNNING | 172.18.66.69 (eth0)  | fd42:1a11:f361:fc2f:216:3eff:fe40:6f76 (eth0) | PERSISTENT | 0         |
#   +----------+---------+----------------------+-----------------------------------------------+------------+-----------+
#   
#   $ cat bootstrap-kube-cenos.sh | lxc exec kmaster bash
#   [TASK 1] Install docker container engine
#   [TASK 2] Enable and start docker service
#   [TASK 3] Add yum repo file for kubernetes
#   [TASK 4] Install Kubernetes (kubeadm, kubelet and kubectl)
#   [TASK 5] Enable and start kubelet service
#   [TASK 6] Install and configure ssh
#   [TASK 7] Set root password
#   [TASK 8] Install additional packages
#   [TASK 9] Initialize Kubernetes Cluster
#   [TASK 10] Copy kube admin config to root user .kube directory
#   [TASK 11] Deploy flannel network
#   [TASK 12] Generate and save cluster join command to /joincluster.sh
#
#   $ lxc list
#   +----------+---------+------------------------+-----------------------------------------------+------------+-----------+
#   |   NAME   |  STATE  |          IPV4          |                     IPV6                      |    TYPE    | SNAPSHOTS |
#   +----------+---------+------------------------+-----------------------------------------------+------------+-----------+
#   | kmaster  | RUNNING | 172.18.74.67 (eth0)    | fd42:1a11:f361:fc2f:216:3eff:fe57:9bbe (eth0) | PERSISTENT | 0         |
#   |          |         | 172.17.0.1 (docker0)   |                                               |            |           |
#   |          |         | 10.244.0.1 (cni0)      |                                               |            |           |
#   |          |         | 10.244.0.0 (flannel.1) |                                               |            |           |
#   +----------+---------+------------------------+-----------------------------------------------+------------+-----------+
#   | kworker0 | RUNNING | 172.18.66.69 (eth0)    | fd42:1a11:f361:fc2f:216:3eff:fe40:6f76 (eth0) | PERSISTENT | 0         |
#   +----------+---------+------------------------+-----------------------------------------------+------------+-----------+

# This script has been tested on Ubuntu 20.04
# For other versions of Ubuntu, you might need some tweaking

# Install docker from Docker-ce repository
echo "[TASK 1] Install docker container engine"
yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
yum install -y -q docker-ce-19.03.5 >/dev/null 2>&1

# Enable docker service
echo "[TASK 2] Enable and start docker service"
systemctl enable docker >/dev/null 2>&1
systemctl start docker

# Add yum repo file for Kubernetes
echo "[TASK 3] Add yum repo file for kubernetes"
cat >>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install Kubernetes
echo "[TASK 4] Install Kubernetes (kubeadm, kubelet and kubectl)"
yum install -y -q kubeadm-1.17.1 kubelet-1.17.1 kubectl-1.17.1 >/dev/null 2>&1

# Start and Enable kubelet service
echo "[TASK 5] Enable and start kubelet service"
systemctl enable kubelet >/dev/null 2>&1
echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/sysconfig/kubelet
systemctl start kubelet >/dev/null 2>&1

# Install Openssh server
echo "[TASK 6] Install and configure ssh"
yum install -y -q openssh-server >/dev/null 2>&1
sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl enable sshd >/dev/null 2>&1
systemctl start sshd >/dev/null 2>&1

# Set Root password
echo "[TASK 7] Set root password"
echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

# Install additional required packages
echo "[TASK 8] Install additional packages"
yum install -y -q which net-tools sudo sshpass less >/dev/null 2>&1

# Hack required to provision K8s v1.15+ in LXC containers
mknod /dev/kmsg c 1 11
chmod +x /etc/rc.d/rc.local
echo 'mknod /dev/kmsg c 1 11' >> /etc/rc.d/rc.local

#######################################
# To be executed only on master nodes #
#######################################

if [[ $(hostname) =~ .*master.* ]]
then

  # Initialize Kubernetes
  echo "[TASK 9] Initialize Kubernetes Cluster"
  kubeadm init --pod-network-cidr=10.172.0.0/16 --ignore-preflight-errors=all >> /root/kubeinit.log 2>&1

  # Copy Kube admin config
  echo "[TASK 10] Copy kube admin config to root user .kube directory"
  mkdir /root/.kube
  cp /etc/kubernetes/admin.conf /root/.kube/config

  # Deploy flannel network
  echo "[TASK 11] Deploy flannel network"
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml > /dev/null 2>&1

  # Generate Cluster join command
  echo "[TASK 12] Generate and save cluster join command to /joincluster.sh"
  joinCommand=$(kubeadm token create --print-join-command 2>/dev/null)
  echo "$joinCommand --ignore-preflight-errors=all" > /joincluster.sh

fi

#######################################
# To be executed only on worker nodes #
#######################################

if [[ $(hostname) =~ .*worker.* ]]
then

  # Join worker nodes to the Kubernetes cluster
  echo "[TASK 9] Join node to Kubernetes Cluster"
  sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.lxd:/joincluster.sh /joincluster.sh 2>/tmp/joincluster.log
  bash /joincluster.sh >> /tmp/joincluster.log 2>&1

fi

