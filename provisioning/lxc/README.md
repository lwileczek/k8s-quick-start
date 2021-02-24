# LXD Kubernetes Cluster

Assuming you have LXD installed already, this directory will spin up a minimum
Kubernetes installation inside of LXC containers. You can choose to deploy
centOS7 containers or Ubuntu 18.04 containers. 

## Outcome

Running the default values will produce 3 nodes, 1 master and 2 workers. All nodes will have a 2 core limit and 2GB memory limit. 

## Deployment

Do start LXD, provision LXC containers, and deploy kubernetes run:

```shell
$ sudo ./deploy
```

## ToDo

  - [ ] Add args options to deploy ubuntu or centos contains at runtime
  - [ ] Add versioning to centos deployment
  - [ ] Add option to choose k8s version at deployment

