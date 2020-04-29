# Controller

This will be used to setup a jumpbox that will be use to connect to the cluster
and where kubespray will be deployed from.  This is to generate a remote
controller for networking and consistent setup reasons. 

## Tasks

This role will generate an SSH key on the controller, pass the public key to all
of the remote servers, and then prepare [kubespray](https://kubespray.io) to be
deployed. 

## Manual user tasks

users must login to the jump server to actually start kubespray.  This gives the
user the flexibility to make last minute changes before deploying. 

## Variables:

  - deploy\_user:  Name of the user on each box that will be used. Default:
    `devops-admin`
  - cluster\_name:  The name of the cluster that will be passed to kubespray.
    Default: `mycluster`
  - release\_branch: The branch of Kubesrpay to use. Default: `release-2.12`
  - node\_os:  The os of the systems you are deploying to. Default: `ubuntu`

