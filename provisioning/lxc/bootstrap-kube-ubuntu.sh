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
#   [TASK 3] Add apt repo file for kubernetes
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


# Install docker from Docker-ce repository
echo "[TASK 1] Install docker container engine"
apt-get install -y  apt-transport-https  ca-certificates  curl  gnupg-agent  software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update && apt-get install -y \
  containerd.io=1.2.13-1 \
  docker-ce=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:19.03.8~3-0~ubuntu-$(lsb_release -cs)

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker

# Enable docker service
echo "[TASK 2] Enable and start docker service"
# systemctl enable docker >/dev/null 2>&1
# systemctl start docker

# Add APT repo file for Kubernetes
echo "[TASK 3] Add apt repo file for kubernetes"
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Install Kubernetes
echo "[TASK 4] Install Kubernetes (kubeadm, kubelet and kubectl)"
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
 
# Start and Enable kubelet service
echo "[TASK 5] Enable and start kubelet service"
systemctl enable kubelet >/dev/null 2>&1
echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/sysconfig/kubelet
systemctl start kubelet >/dev/null 2>&1

# Install Openssh server
echo "[TASK 6] Install and configure ssh"
apt install -y -q openssh-server >/dev/null 2>&1
sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl enable ssh >/dev/null 2>&1
systemctl start ssh >/dev/null 2>&1

# Set Root password
echo "[TASK 7] Set root password"
echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

# Install additional required packages
echo "[TASK 8] Install additional packages"
apt install -y sshpass >/dev/null 2>&1

# Hack required to provision K8s v1.15+ in LXC containers
# mknod /dev/kmsg c 1 11
# chmod +x /etc/rc.d/rc.local
# echo 'mknod /dev/kmsg c 1 11' >> /etc/rc.d/rc.local

#######################################
# To be executed only on master nodes #
#######################################

if [[ $(hostname) =~ .*master.* ]]
then

  # Initialize Kubernetes
  echo "[TASK 9] Initialize Kubernetes Cluster"
  kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all >> /root/kubeinit.log 2>&1

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

