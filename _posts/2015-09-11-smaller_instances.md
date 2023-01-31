---
layout: post
title: You don't need a bigger instance
description: Amazon Web Services offer massive instances but if you structure your application properly you don't need them
date: 2015-09-11 14:10:00 +0000
categories: [DevOps, AWS]
tags: [aws, devops]
---

I am a big fan of Amazon Web Services and host a lot of projects there. One thing I keep on hearing from people when they first start using AWS is that they need a bigger instance. I have heard over and over again that 'we need 4xlarge instance to run our application', that normally means it has not been designed properly for the cloud.

If the only answer is a bigger instance then you're probably doing it wrong!

## Structuring a web application

Web based applications are likely to be the common use case people are facing and they are a prime example of bigger not being better. All web applications are roughly the same from a very high level:

1. A request comes it
2. The application does things e.g. accessing a database, call an api etc
3. The application generates a response, which could be an html page, json or anything else
4. The response is sent

While applications are all different but most will follow this basic pattern. If that is what you are doing then why would you ever need anything larger than medium sized instance?

{% include ad-top-text.html %}

The great benefit of hosting an application on AWS is that your application can scale. Amazon offer some great tools to help with this. My favorite approach is Elastic Beanstalk that allows you to host an application, written in a variety of languages or in a Docker container, with auto scaling built in. Most web applications should be able to fit into the Elastic Beanstalk pattern and increase the number of nodes you need when the traffic increases. For more complex applications there is option of AWS Ops Works or Cloud Formation to archive the same effect. In either case there should not be a need to go above a medium instance.

AWS based applications should be able to scale horizontally, meaning that if your application needs more power the solution is more servers rather than bigger servers. The advantage is that you have far greater redundancy in your application and you have the option to scale down when the load reduces.

## My application needs more resources

There are times when a process needs to use more resources than you can get from medium instances. If that is the case then it's time to think about how the application works.

Here are just a few questions to ask

* Why can't I just add more nodes?
* Am I using the file system when I should be using a database?
* Does my application do things that should be passed off the a queue for processing later?
* Is my application too big and should I split it up?

{% include ad-bottom-text.html %}

I'm not suggesting every application can be split up like this, if you are doing some heavy data processing then yes larger instances might be needed but for a web based application it is worth thinking about.

The big danger of AWS is the temptation to think the resources are unlimited and that you can start those large instances whenever you need to. The problem is that once that mindset is in your team those large instances add up quickly and you are hiding a problem in the code by add more resources.

## My process only runs quickly and then shuts down

Sometimes an application will only need to run and then shutdown the instances. Anything that responds to events might fit that pattern or test cases in a continus integration environment.

It is less of the problem with this situation because your large instances are not always running but the same issues still apply.

There is nothing wrong with a larger instance if you can justify it but be careful about making sure you actually can.
