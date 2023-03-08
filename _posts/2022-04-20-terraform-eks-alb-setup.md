---
layout: post
title: Setting up EKS with Terraform, Helm and a Load balancer
description: Use Terraform to deploy a new AWS Elastic Kubernetes Cluster with a Helm chart and Application Load Balancer
date: 2022-04-20 01:10:00 +0000
categories: [DevOps, AWS, Terraform, EKS, Kubernetes]
tags: [aws, terraform, kubernetes, eks]
---

Setting up a new Kubernetes cluster is a common task for DevOps Engineer these days and in the past few months I've had a set up several. These have normally been on AWS using the Elastic Kubernetes Service and Terraform. In this article I want to share my approach to setting up a new cluster and installing the ALB addon to actually allow traffic to your applications. To allow traffic into our cluster we need to link our Kubernetes ingress to an AWS Load Balancer user the ALB Controller.

## Setting up EKS

Kubernetes is a complex tool and AWS provide a lot of options to meet almost any need. The problem with that is that it can give you too many options and it can be a little overwhelming. 

{% include ad-top-text.html %}

Here is the module I generally use

```terraform
  resource "aws_security_group" "eks" {
    name        = "${var.env_name} eks cluster"
    description = "Allow traffic"
    vpc_id      = var.vpc_id

    ingress {
      description      = "World"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    tags = merge({
      Name = "EKS ${var.env_name}",
      "kubernetes.io/cluster/${local.eks_name}": "owned"
    }, var.tags)
  }

  module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "18.19.0"

    cluster_name                    = var.eks_name
    cluster_version                 = "1.21"
    cluster_endpoint_private_access = true
    cluster_endpoint_public_access  = true
    cluster_additional_security_group_ids = [aws_security_group.eks.id]

    vpc_id     = var.vpc_id
    subnet_ids = var.private_subnet_ids

    eks_managed_node_group_defaults = {
      ami_type               = "AL2_x86_64"
      disk_size              = 50
      instance_types         = ["t3.medium", "t3.large"]
      vpc_security_group_ids = [aws_security_group.eks.id]
    }

    eks_managed_node_groups = {
      green = {
        min_size     = 1
        max_size     = 10
        desired_size = 3

        instance_types = ["t3.medium"]
        capacity_type  = "SPOT"
        labels = var.tags 
        taints = {
        }
        tags = var.tags
      }
    }

    tags = var.tags
  }
```

So there's a lot going on here but lets cover the main points.

1. First we have a security group to open up the cluster. This cluster will run in a private subnet of a VPC so we are not actaully opening this to the world. Despite this I would suggest restricting the security group but for these purposes we will use this open group.
1. Next we have the eks module. For this we're pulling in an open source module that will do most of the work for us. 
1. At the top we define various cluster properties like the name, endpoint details and security groups. 
1. The VPC and subnet ids need to be defined. We are passing the private subnet ids so the instances will not be publically accessable.
1. Finally we define node groups, we provide the size of the instances and details of the auto scaling group.

This cluster will create a small cluster with spot instances. Now we have everything we need for a basic cluster that can run our appliation.

## Adding the Load Balancer Controller

In order to install the load balancer controller you first need to grant access via an IAM role. Fortunatly there is a simple module for this

```terraform
module "lb_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.env_name}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}
```

This module will add an iam policy to the cluster to allow the creation of load balancers. Remember the `namespace_service_accounts` line, it is assuming you are going to create a service account in the `kube-system` namespace called `aws-load-balancer-controller`. Thats the default location that is used in the documentation. If you need to use a different namespace or service account name then thats fine but remember to update this module.

First we need to configure kubernetes and the service account. This service account won't do anything to start with but we need to get it ready for the controller.

```terraform
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_cert)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_cert)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}

resource "kubernetes_service_account" "service-account" {
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
        "app.kubernetes.io/name"= "aws-load-balancer-controller"
        "app.kubernetes.io/component"= "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_role.arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

```

To install the actually controller there is a helm chart. To keep all the configuration together we are going to use helm from Terraform.

```terraform
resource "helm_release" "lb" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service-account
  ]

  set {
    name  = "region"
    value = "eu-west-2"
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.eu-west-2.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = var.eks_name
  }
}
```

Here we are deploying a helm chart from Terraform. The important thing to be careful about are the region configuration. Here we are using the AWS EU-West-2 region in London. If you are using a different region you will need to change the region variable but also the `image.repository`. [AWS provide repos in each region](https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html) so if you using another region then make sure you change it.

{% include ad-bottom-text.html %}

## Deploy your application

Below is the ingress configuration for a simple load balancer. This will create an ALB thats connected to your ingress. The annotations are documented in the [ALB Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/ingress/annotations/) so you can configure certifications, internet facing load balancers and detailed routing rules.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {% raw %}{{ .Values.fullname }}-lb{% endraw %}
  annotations:
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: instance
    alb.ingress.kubernetes.io/load-balancer-name: {{ .Values.fullname }}
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
spec:
  ingressClassName: alb
  defaultBackend:
    service:
      name: {% raw %}{{ .Values.fullname }}{% endraw %}
      port:
        number: {% raw %}{{ .Values.service.port }}{% endraw %}
```

## Summary

This should give most of the boilerplate that you need to get a cluster up and running with Terraform and EKS. Unfortunatly it does require some connected resources to get it to work and it would be better if this could be simplifeid further with AWS but this should help you get your cluster going
