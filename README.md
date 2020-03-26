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
3GB transfer speeds accessible from anywhere with internet connection.

