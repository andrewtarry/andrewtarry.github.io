---
layout: post
title: Custom DNS in Kubernetes
description: DNS in Kubernetes is a great but if you need custom entries you will need to modify the CoreDNS service
date: 2023-01-31 01:10:00 +0000
categories: [Kubernetes, DNS, CoreDNS]
tags: [Kubernetes, DNS]
---

Within a Kubernetes cluster, DNS is normally handled by CoreDNS. This is started by default, and it will provide internal routing for services. Most of the time that’s fine and it will allow all our Kubernetes services to talk to each other as well as to the rest of the internet. Some cloud providers also enhance this with their own DNS settings.

The problem I faced was that I have Kubernetes on my home lab with [microK8s]( https://microk8s.io/) and I need some custom DNS records. I found that the DNS inside the cluster was totally different to the addresses from outside the cluster and that caused confusion depending on where the application was running. 

I needed custom records to reach services on my home network that did not have public DNS.

{% include ad-top-text.html %}

## Approach 1 – Hosts

The easiest way to add hosts to a `pod` is in the `deployment`. To do this I updated the deployment to include `hostAliases` key. 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 1
  template:
    spec:
      hostAliases:
      - ip: "192.168.10.14"
        hostnames:
        - "plex.lab.home" 
      containers:
```

The `hostAliases` key works in a very similar way to the `/etc/hosts` file on Linux and Mac systems. It allows custom hostnames to be matched to IP addresses for that system. In Kubernetes it will be applied to all the containers in the `pod`.

The problem is that this method requires additional Kubernetes configuration in every deployment. That can be handled with Helm templates and helpers but it would be nice to put all this in one place.

## Approach 2 – CoreDNS Hosts

A better way to handle this would be to update the CoreDNS service to use these hosts. CoreDNS is a very flexible tool and I would try to set up additional DNS server but it is possible to define the custom hosts directly in CoreDNS.

First open up the CoreDNS configmap

```
kubectl -n kube-system edit configmaps coredns
```

```yaml
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . 172.16.0.1
        cache 30
        loop
        reload
        loadbalance
    }
kind: ConfigMap
```

To add custom hosts add a new block to the bottom that lists the host you need.

```yaml
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . 172.16.0.1
        cache 30
        loop
        reload
        loadbalance
    }
    lab.home:53 {
        errors
        hosts {       
            192.168.10.14 plex.lab.home       
        }
    }
kind: ConfigMap
```

{% include ad-bottom-text.html %}

Save the changes the CoreDNS will update itself with the new config. Now you can access your custom hosts from any pod in the cluster.

## Summary

DNS is always extremely helpful and it’s great that Kubernetes offers a good system like CoreDNS. Unfortunately, the documentation is a bit limited, but this approach is now working for me.
