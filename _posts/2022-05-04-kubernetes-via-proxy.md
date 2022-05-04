---
layout: post
title: Connecting to Kubernetes via a Proxy
description: Using Kubernetes via a proxy presents unique challanges because the way to connect requires the undocumented proxy-url to be set
date: 2022-05-04 01:10:00 +0000
categories: [DevOps, Kubernetes]
tags: [kubernetes]
---

Kubernetes has come to dominate the DevOps world, and it can be hard to imagine a project without it. The problem is that even if you have a nice new Kubernetes instance to use, you might still have to deal with legacy CI servers to do the actual deployment.

## The problem set up

One of the common arrangements is when the CI server sits somewhere different from the Kubernetes environment. Often the CI server is managed by one team, and the development, test and production environments exist somewhere else. One of the most common patterns we see is a proxy sitting between your CI server and the rest of your infrastructure.

![Kubernetes via a proxy](/assets/img/kubernetes/kubernetes-behind-proxy.png)

This proxy usually is doing things like rewriting URLs, managing security or just logging requests, but it's your only route to get the job done.

I certainly don't recommend this setup, but it remains common with many legacy organisations. The problem is that you now need `kubectl` and other related tools to understand and respect your proxy.

## Managing kubernetes requests

The obvious approach would be to use the standard `http_proxy` and `https_proxy` to send requests. The problem is that `kubectl` is not consistent with these variables, some people have been able to get them to work, but others haven’t. I know I couldn’t get them to work properly and even you can, they are fairly crude. 

The problem with the proxy environment variables is that they can be hard to debug and if you have to deal with more than one proxy, you are going to have to constantly change them. You need a way to set a proxy that `kubectl` will use directly.

## Setting the proxy-url

Kubernetes configuration is managed in your local system's `~/.kube/config` file. Yours will look something like this:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: xxxxxxxxx
    server: https://my.dev.server
  name: my-dev
contexts:
- context:
    cluster: my-dev
    user: myusername
  name: dev
current-context: dev
kind: Config
preferences: {}
users:
- name: myusername
  user:
    token: xxxxx-yyyyyy-zzzzz
```

This style of yaml file will be familiar to most people using Kubernetes. If you have more servers and contexts in place, your file will be a lot larger but you will still have the `clusters`, `contexts` and `users`  objects.

To set a proxy you can modify the cluster object as follows:

```yaml
clusters:
- cluster:
    certificate-authority-data: xxxxxxxxx
    server: https://my.dev.server
		proxy-url: http://internal.proxy.local:1234
  name: my-dev

```

In this example, we add the `proxy-url` key to the `cluster` so that `kubectl` will send all its requests via the internal proxy.

Unfortunately, there does not seem to be any documentation on this key so it was hard to find out how to use it. There is also no way to set it via the command line as with most of the other configuration. The only option is to open the config file and add it manually.

Despite these pains, this option will allow you to set a proxy per cluster and connect to Kubernetes despite your internal tools.