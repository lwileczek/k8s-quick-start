#!/bin/bash

# Install Kubernetes inside a ubuntu container
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
#   $ cat bootstrap-kube-ubuntu.sh | lxc exec kmaster bash
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


# Enable docker service
echo "[TASK 2] Enable and start docker service"
systemctl daemon-reload
systemctl restart docker

# Add APT repo file for Kubernetes
echo "[TASK 3] Add apt repo file for kubernetes"
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Install Kubernetes
#TODO: Download k8s tree and set version number for installation
#  StackOverflow: https://stackoverflow.com/questions/49721708/how-to-install-specific-version-of-kubernetes
#  Get k8s versions: curl -s https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages | grep Version | awk '{print $2}'
echo "[TASK 4] Install Kubernetes (kubeadm, kubelet and kubectl)"
apt-get update
apt-get install -qy kubelet=1.17.6-00 kubectl=1.17.6-00 kubeadm=1.17.6-00
apt-mark hold kubelet kubeadm kubectl
 
# Start and Enable kubelet service
# echo "[TASK 5] Enable and start kubelet service"
# systemctl enable kubelet >/dev/null 2>&1
# echo 'KUBELET_EXTRA_ARGS="--fail-swap-on=false"' > /etc/sysconfig/kubelet
# systemctl start kubelet >/dev/null 2>&1

# Install Openssh server
echo "[TASK 6] Install and configure ssh"
apt install -y -q openssh-server >/dev/null 2>&1
sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
systemctl enable ssh >/dev/null 2>&1
# systemctl start ssh >/dev/null 2>&1
systemctl restart ssh >/dev/null 2>&1

# Set Root password
echo "[TASK 7] Set root password"
echo "root:kubeadmin" | chpasswd >/dev/null 2>&1


# Install additional required packages
echo "[TASK 8] Install additional packages"
apt install -y sshpass >/dev/null 2>&1

# Hack required to provision K8s v1.15+ in LXC containers
# mkdir -p /proc/sys/net/bridge
# echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
swapoff --all
# https://github.com/kubernetes/kubernetes/issues/53533#issuecomment-365495719
# edit /etc/systemd/system/kubelet.service.d/conf*
# Add --fail-swap-on=false
# working on it. 
sed -i -E 's/(^Environment=".*)"/\1 --fail-swap-on=false"/' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload
mknod /dev/kmsg c 1 11
touch /etc/rc.local
chmod +x /etc/rc.local
echo 'mknod /dev/kmsg c 1 11' >> /etc/rc.local

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
