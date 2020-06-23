#/bin/bash
#
# bootstrap-lxc.sh
# Setup a kubernetes cluster inside of LXC Containers on a linux system. Default
# is to set up three nodes, one master and two worker nodes.
#
# Assumptions:
# - The following packages are installed
#   - LXC
#   - LXD
#   - cURL
# - OS is Linux
# - Being deployed from the same folder as
#   - profile.yaml
#   - lxd_init.yaml
#   - bootstrap-kube-centos.sh
# - Running as root
#
# Invoke:
# ./boostrap-lxc.sh

cat ldx_init.yaml | lxd init --preseed  # take our file to start lxd

lxc storage create k8s-storage dir  # local storage
lxc profile create k8s-profile
cat k8s-profile.yaml | lxc profile edit k8s-profile

# Launch three CentOS containers
for node in kmaster kworker0 kworker1
do
    lxc launch images:ubuntu/18.04 ${node} --profile k8s-profile
    cat bootstrap-kube-ubuntu.sh | lxc exec ${node} bash
done

exit 
# Platform agnositc kubectl download
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
# To download a specific version you can use the below replacing `v1.18.0` with
# the desired version.
#  curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl

chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
mkdir ~/.kube

