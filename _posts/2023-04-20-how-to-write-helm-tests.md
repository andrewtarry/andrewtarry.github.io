---
layout: post
title: How to write a Helm Test
description: Helm tests are a built-in feature that allows you to create and run tests for your Helm charts. These tests are essential for validating the functionality and performance of your applications
date: 2023-04-20 04:10:00 +0000
categories: [Bid, Project Management]
tags: [Project Management, Bid]
og_image: /assets/img/kubernetes/sea-captain-1200.png
image: /assets/img/kubernetes/sea-captain-800.png
---

Helm is a powerful package manager for Kubernetes, offering an efficient way to manage, deploy, and maintain applications in a Kubernetes cluster. One of the key features Helm offers is the ability to run tests on your applications, ensuring their stability and reliability. In this blog post, we'll explore Helm tests, why they're important, and walk through some practical code samples to help you get started.

## What are Helm Tests?

Helm tests are a built-in feature that allows you to create and run tests for your Helm charts. These tests are essential for validating the functionality and performance of your applications. They help in identifying potential issues and errors before they're deployed to a live environment, ensuring that your applications remain stable and resilient.

Once your deployment is complete you can run a set of containers within your cluster that will help you to know the deployment has worked.

{% include ad-top-text.html %}

## Why Use Helm Tests?

Helm can do some interesting things if there is a problem. A common occurrence is for a Helm update to complete but the containers do not start due to a problem. The pipeline has passed but the service is now down. If you have readiness checks enabled then the service might still be working with the old version and the new one is crashing. For a minor change this might not be obvious until you look into it further.

Helm tests are not the only way to test your release, but they have some advantages. First, they are a built in feature of Helm so they are available now and easy to use. Second, you can run the test container in the same namespace the services. That means you have strong network security but still expose the internal details to the test.

A common test is to validate the service version number in the test. That might not be information that you want to expose publicly but you can use Helm tests to access to local port or path that is only available inside your namespace.

Having a suite of tests that validate the functionality of your application can give you greater confidence in your deployments, especially when working with complex, distributed systems.

## How to Write Helm Tests

Helm tests are defined as Kubernetes manifest files, typically written in YAML. To create a test, you'll need to add a new manifest file to the templates/tests directory within your Helm chart. This file will define a Kubernetes Pod or Job, with the helm.sh/hook: test annotation, which specifies that this resource is a test.

Let's walk through a simple example to demonstrate how to write a Helm test. Suppose you have a basic web application deployed using a Helm chart. You want to create a test that ensures your application is responding to HTTP requests.

Create a new file in the templates/tests directory, named http-check.yaml.

Add the following YAML to define a test Pod:

```yaml
{%- raw %}
apiVersion: v1
kind: Pod
metadata:
  name: "{{ .Release.Name }}-http-check"
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: http-check
      image: busybox
      command: ['wget']
      args: ['--spider', '--timeout=5', 'http://{{ .Release.Name }}.{{ .Release.Namespace }}.svc.cluster.local']
  restartPolicy: Never
{% endraw -%}
```

In this example, we've defined a simple Pod that runs the wget command to send an HTTP request to the application's service. If the request is successful, the test will pass; otherwise, it will fail.

Notice the `helm.sh/hook: test` annotation. This will tell Helm to run this container only when you ask for the tests to be executed. 

This test will prove that the release is working and the service is returning successful status codes. It’s very simple, but you can make it more complex. 

Thanks to Helm, you have a range of custom variables that you can use, as well as the option of using a custom container. 

```yaml
{%- raw %}
apiVersion: v1
kind: Pod
metadata:
  name: "{{ .Release.Name }}-version-check"
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: verion-check
      image: privaterepo/versionchecker:latest
      command: ['versioncheck']
      args: ['{{ .Values.current_version }}']
  restartPolicy: Never
{% endraw -%}
```

Now we have a custom container and are passing in the version number from our `values.yaml`. This container could contain a script that calls various API’s and checks version numbers compared to what was passed in. If you can write a script, you can do it in a Helm test.

{% include ad-bottom-text.html %}

## Running Helm Tests

To run your Helm tests, you'll need to install or upgrade your Helm chart. Once your chart is deployed, you can use the following command to run your tests:

```
helm test <release-name>
```

Replace <release-name> with the name of your Helm release. The command will output the test results, indicating whether they passed or failed.

## Conclusion

Helm tests are powerful if you want to be sure a new release has gone as expected. They will not replace other tests in your pipeline, but they are another tool available to the diligent engineer. 
