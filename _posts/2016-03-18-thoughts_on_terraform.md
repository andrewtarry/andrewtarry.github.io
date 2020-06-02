---
layout: post
title: Thoughts on Terraform
description: Terraform is a great tool for managing AWS but there few issues with it.
date: 2016-03-18 14:10:00 +0000
categories: [DevOps, Terraform]
tags: [terraform]
---

I recently go involved in a number of projects using [Terraform](https://www.terraform.io) to create AWS environments. Having spent a lot of the last few weeks looking at nothing but Terraform here are some of my thoughts about it. 

Terraform does support a lot more providers that AWS but I've not tried them so I'm not going to talk about them here.

## It's great

First things first, Terraform is extremely powerful and much easier to work with than manually setting things up in the AWS UI or Cloudformation. It's syntax is clear enough that you can understand it without too much work and it's declarative so your environment should never get out of sync.

I was really impressed with how easily I could create an auto-scaling web application. Getting the first version of your app running takes a lot of code to add a VPC, subnets, security groups, launch configuration, auto scaling, elastic load balancer, route 53 records and anything else you need but that's a lot of things you're creating. Once that first app is up and running you can add more or create multiple environments so easily. I'm not going to give a long code example here, [Hashicorp has some good ones](https://github.com/hashicorp/terraform/tree/master/examples/aws-two-tier).

Considering how long it normally takes to create a large scale environment manually I think Terraform is going to greatly relive the DevOps world. A few well made Terraform files and you can manage that environment easily.

### It's better than doing it manually

Isn't automation always better? Terraform is faster than doing it manually thanks to parallel processing and not needing to click around screens. It's also easier because your're not copying id's around everywhere. 

Terraform files can be stored in source control so you can treat it the same ways any other code.

### It's easier than CloudFormation

Anyone who has used CloudFormation will know it's not easy. Maintaining large json documents is not a particularly easy way to work and the documentation is sometimes hard to penetrate. CloudFormation is extremely powerful but I'm much happier working with Terraform files than trying to build a complex environment in CloudFormation.

## There are problems

I think the big problem for Terraform is that it is still immature and it lacks a few key features that would make it really great. The developers involved have done an amazing job with it and I really hope they continue to add features because I think Terraform is right on the cusp of being the go to tool for AWS automation.

### If's and loops

I would love to see some proper control structures in the Terraform syntax. There are times when some features should be on in one environment but not another. For example you might want CloudFront for your production or staging environments but not development, or you might need to stub a third party api in development but not in production. At the moment there's not a way to do this, you can use variables per environment to change the name and size of your resource but not to turn them off completely. I know some people will argue that by making environments different it's risking bugs but sometimes you need to and the tool should support it, it's up to your team if they think it's a good idea.
 
 Loops in Terraform are sort of available but they are a bit horrible. 
 
```hcl
resource "template_file" "my_template" {
    count = "${length(split(",", var.things))}"
    template = "${file("${path.module}/cloudfront.cf.json")}"
    vars {
     thing = "${element(split(",", var.things), count.index)}"
    }
}

resource "aws_cloudformation_stack" "my_stack" {
    count = "${length(split(",", var.things))}"
    name = "things-${element(split(",", var.things), count.index)}"
    template_body = "${element(template_file.my_template.*.rendered, count.index)}"
}
```

Here is an example of why I don't like the current approach. We have a comma separated string of `things` that create a number of templates and use those templates to create CloudFormation stacks (I'm just using CloudFormation as an example but this is fairly common). The reliance on splitting strings and using indexes makes the code hard to understand and easy to mess up. It's also extremely limited, if you have more that 1 variable then you have to use 2 comma separated strings that have their values in the right order so you can split them in the right way. The danger in a large environment is enormous.
 
There are feature requests open for these issues but they have not been added yet. It's a complex thing to code so I understand they take time but I'm really hoping to see them soon.

{% include googleAd.html %}
 
### Declarative commands
 
Terraform is declarative tool, i.e. put your configuration in and Terraform will ensure your environment matches. In theory that's great because your configuration and actual environment remain in sync. The problem is that Terraform will always need to make sure your environment is correct and depending on what the problem is it might need to terminate resources to get it there. In a development environment that's fine but I don't want the risk that my production database is going to be replaced because someone made a minor change and didn't read their plan properly. 

The problem with the declarative approach is that once you run the plan you cannot then pick and choose what you want to do. Terraform plan will tell you what it's going to do and if there are some resources that you don't want it to touch you need to go over the history of that configuration to undo whatever is causing the change. What I would like to see is an option to just change the bits I want to change.

### Missing resources

Ok, this is just an annoyance rather than real problem but there are a number of resources missing from some of the major providers. Terraform have some really good documentation to add your own providers and there are number of new ones being reviewed at the moment but it's still a problem when the thing you need isn't there. Adding new providers is not for everyone, you will need Go developers or people with the time to learn it so if you're not in the Go world adding a new resource might not be realistic. This problem is likely to arise when you want to add that great new feature to your environment but then you see there's no support for it when you would expect it to be there. 

These things take time and I don't want to sound like I don't appreciate the work of the Terraform developers because I do and I'm honestly amazed they manage to support so much without an enormous team. I think they've done a great job and hope they continue adding new features but when it comes to the provisioning your environment you need to take that into account. Are there a lot of new features on the roadmap? What will they need? Is there support of them?

### Changes between versions

Terraform is still fairly new so it's still a little unstable. The result is that patch versions can make a big difference. The code base is large and there are lots of moving parts so jumping from one version to another can have a lot of consequences. I would suggest keeping a close eye on releases and test very carefully, strange things can happen in a new patch. 

A degree of instability is common in new tools and again I don't want to sound negative but does need to be considered. Once your environment is up, the last thing you want is to be blocked by a bug in a new version when you need that new bit of functionality.
 
## I'll stop complaining

Ok, I'm done. Terraform is a great tool and I would highly encourage you to consider it. I have listed some problems here that make it difficult but it's still my tool of choice for building AWS environments. Terraform is young, immature but powerful and has a great community. In a year or so I'm expecting it have these rough edges smoothed off and we'll have a fantastic tool, for now I still think use it but do so with caution. 

I'll be watching Terraform with a lot of excitement and I'm really looking forward to see it improve further.