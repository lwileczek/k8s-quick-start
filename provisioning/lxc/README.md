# LXD Kubernetes Cluster

Assuming you have LXD installed already, this directory will spin up a minimum
Kubernetes installation inside of LXC containers. You can choose to deploy
centOS7 containers or Ubuntu 18.04 containers. 

## Deployment

Do start LXD, provision LXC containers, and deploy kubernetes run:

```shell
$ source deploy-lxc-cluster.sh
```

## ToDo

  - [ ] Add args options to deploy ubuntu or centos contains at runtime
  - [ ] Add versioning to centos deployment
  - [ ] Add option to choose k8s version at deployment

