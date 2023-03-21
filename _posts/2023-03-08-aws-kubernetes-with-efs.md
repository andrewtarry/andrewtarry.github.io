---
layout: post
title: Setting up AWS EKS using EFS with Terraform
description: Use Terraform to deploy a new AWS Elastic Kubernetes Cluster with the Elastic File System to provide volumes
date: 2023-03-08 01:10:00 +0000
categories: [DevOps, AWS, Terraform, EKS, Kubernetes, EFS]
tags: [AWS, Terraform, Kubernetes, EKS]
og_image: /assets/img/aws-efs/EKS_EFS_diagram.png
---

![EKS EFS Diagram](/assets/img/aws-efs/EKS_EFS_diagram.png)

Using AWS EKS is great for large-scale services but what happens when you need a shared filesystem? Some applications need to share a filesystem to work properly so you need to set up some volumes. If you only need one node to be able to use a volume at once then an EBS is ideal. For more complex needs with lots of reads and writes from different nodes you need EFS.

## What is EFS

EFS, also known as the Elastic File System, is a NFS based service within AWS. It allows multiple EC2 instances to share the same mounted directories within the file system at the same time. 
It is different from EBS because EBS is basically a persistent drive. You can use it to save files, turn off the EC2 instance and then add the EBS to a new server. That’s great for ensuring the files are safe but it does not support multiple instnaces using the files at the same time. For that you need EFS.

{% include ad-top-text.html %}

## Setting up EFS on Kubernetes

If you have seen my previous [AWS Kubernetes articles on setting up load balancers](https://andrewtarry.com/posts/terraform-eks-alb-setup/) you will have seen the Terraform module used to create the cluster. 

```tf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.project_key
  cluster_version = "1.24"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  self_managed_node_group_defaults = {
    instance_type                          = "m6i.large"
    iam_role_additional_policies = {
    }
  }

  eks_managed_node_group_defaults = {
    instance_types = [var.instance_size]
    vpc_security_group_ids = [aws_security_group.eks.id]
  }

  eks_managed_node_groups = {
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = [var.instance_size]
      capacity_type  = "SPOT"

      tags = local.default_tags
    }
  }

}
```

To add EFS we first need to add a security group:

```tf
resource "aws_security_group" "efs" {
  name        = "${var.env} efs"
  description = "Allow traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "nfs"
    from_port        = 2049
    to_port          = 2049
    protocol         = "TCP"
    cidr_blocks      = [module.vpc.vpc_cidr_block]
  }
}
```

And add it to the cluster by finding the `eks_managed_node_group_defaults` in the EKS module above. 

```tf
  eks_managed_node_group_defaults = {
    instance_types = [var.instance_size]
    vpc_security_group_ids = [aws_security_group.eks.id]
  }
```

Next you need to grant IAM roles to the nodes to use EFS.

```tf
resource "aws_iam_policy" "node_efs_policy" {
  name        = "eks_node_efs-${var.env}"
  path        = "/"
  description = "Policy for EFKS nodes to use EFS"

  policy = jsonencode({
    "Statement": [
        {
            "Action": [
                "elasticfilesystem:DescribeMountTargets",
                "elasticfilesystem:DescribeFileSystems",
                "elasticfilesystem:DescribeAccessPoints",
                "elasticfilesystem:CreateAccessPoint",
                "elasticfilesystem:DeleteAccessPoint",
                "ec2:DescribeAvailabilityZones"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": ""
        }
    ],
    "Version": "2012-10-17"
}
  )
}
```

Now you can create the EFS itself

```tf
resource "aws_efs_file_system" "kube" {
  creation_token = "eks-efs"
}

resource "aws_efs_mount_target" "mount" {
    file_system_id = aws_efs_file_system.kube.id
    subnet_id = each.key
    for_each = toset(module.vpc.private_subnets )
    security_groups = [aws_security_group.efs.id]
}

```

Notice I am using a module called `module.vpc` to get the VPC details. If you want to see how that works check out the [Terraform VPC documentation](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).

## Adding the EFS controller

Now that we have EFS running we need to tell Kubernetes about it. AWS provide manifests to set this up. 

```
kubectl kustomize "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.X" > public-ecr-driver.yaml
```

You will need to set the release number to the latest version. In my case that is `1.5.3` but you can find the latest on the (EFS Driver Github)[https://github.com/kubernetes-sigs/aws-efs-csi-driver/releases] page. 

This will give you a large Kubernetes manifest. Open it up and find the Service Account named `efs-csi-controller-sa`. You can add an annotation role arn that you created above, `eks.amazonaws.com/role-arn: <arn>`. Now you can apply with `kubectl apply -f public-ecr-driver.yaml`. 

Finally create the storage class and the volumes.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: <Your filesystem id from EFS, normally starting with fs->

---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: <Your filesystem id from EFS, normally starting with fs->
  directoryPerms: "777"
```

The volume is not available to use.

{% include ad-bottom-text.html %}

## Using the volume

To use the new EFS volume you can create a persistent volume claim and use it with multiple containers.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myvolume
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: website
spec:
  replicas: 2
  selector:
    matchLabels:
      app: website
  template:
    metadata:
      labels:
        app: website
    spec:
      containers:
        - name: website
          image: wordpress:latest
          volumeMounts:   
            - name: myvolume
              mountPath: /var/www/html/wp-content/uploads
              subPath: uploads

      volumes:
        - name: myvolume
          persistentVolumeClaim:
              claimName: myvolume
```


## Summary

EFS is a powerful tool for those using AWS and Kubernetes together. The documentation could be better, but by using the steps here, you should be able to get shared volumes up and running quickly.


