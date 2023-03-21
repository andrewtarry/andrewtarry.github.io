---
layout: post
title: How to use Cron on Kubernetes (2 options)
description: Cron lets you run programmes on a timer. On a Linux server, that’s easy, but how can you use Cron with Kubernetes, there are two options
date: 2023-03-21 09:10:00 +0000
categories: [Kubernetes]
tags: [Kubernetes, Cron]
og_image: /assets/img/cron/clock.png
---

![Clock](/assets/img/cron/clock.png)

Cron is one of those simple tools that it’s hard to imagine life without. It allows us to run a script or a programme at regular intervals. Maybe you want to run a backup at 1am every day or you want to execute a health check every minute. 

With cron, it is simply a case of adding a like to the `crontab` and you’re done. What is the best way to run a cron job inside a Kubernetes cluster?

## Cron and Kubernetes Scenario

Let's imagine you need to run a script that reconciles two databases every 2 hours. The script is called `reconcile.sh`.

This script is not particularly complex to run so it does not need many resources. In a traditional server environment, you could find a server that has the capacity and use the crontab to run your script.

Recently everything has moved to Kubernetes which leaves you with a question.

How could you do the same thing in a Kubernetes environment?

## Option 1: Use the crontab in Kubernetes

The obvious solution would be to use your `dockerfile`.

```dockerfile
FROM ubuntu

# add the script

RUN apt-get update 
RUN apt-get -y install cron 
RUN crontab -l | { cat; echo "* */2 * * * sh /reconcile.sh"; } | crontab –

```

Now you can create a Kubernetes pod, and you’re done.

The problem is that this is not a very efficient solution. You might only be running your job once per day, so do you need to keep a pod running all the time?

There is also the issue of location. when Kubernetes starts a pod it will consider the available nodes, their capacity and any restrictions that exist. If you fill up a node with containers that are barely being used then it make it harder to distribute the load across the rest of the cluster.

## Option 2: Use the Kubernetes CronJob object

Kubernetes actually supports cron by default. It is possible to create pod using a cron schedule and Kubernetes will create it as needed. Once the task is complete the pod will exit and the resources can be used for something else. 

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: reconcile
spec:
  schedule: "* */2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: reconile
            image: reconile:latest
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - /reconcile.sh
```

This approach means that you do not need to include cron in your container since Kubernetes will manage that. You can use all the normal Kubernetes configuration values like Environment Variables, Secrets, Volumes and ConfigMaps.

The `schedule` uses the standard crontab structure. You can run a task every minute, every hour or every week, depending on your needs. If you are unsure about the Cron schedule, use [crontab guru](https://crontab.guru/) to generate the cron expression. 

## Summary

Using the Kubernetes CronJob will be a more efficient way to run your jobs. There are some edge cases when you want to run a job every minute, and the pod is slow to start, so it makes sense to keep it running all the time, but these are rare. For most tasks, a `CronJob` is what you will need.
