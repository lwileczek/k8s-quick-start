# MetalLB

Install a bare metal load balancer for clusters that are not hosted in cloud
providers.  Cloud providers make their load balancers easy to integrate and use
but for private clouds or on premesis cluster you will need your own solution. 

# Documentation 

More information about MetalLB can be found on their [website](https://metallb.universe.tf/). 

Current configuration will setup metalLB in `Layer 2` mode.  Make sure 
`strict ARP mode` is enabled if you are using `kube-proxy`. 

```sh
kubectl edit configmap -n kube-system kube-proxy
```

and set 
```
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true
```

# Load Balancer
This does not deploy a generic load balancer but provides the ability to expose a deployment as `--type=LoadBalancer`. 
For example, after this runs you could do something like:

```sh
$ kubectl create deployment nginx --image=nginx
$ kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

