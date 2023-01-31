---
layout: post
title: Provisioning Vagrant with Chef
description: Provisioning Vagrant with Chef is an extremely powerful way to build your environment but can be hard to learn. This article will give you the basics
date: 2015-05-08 14:10:00 +0000
categories: [DevOps, Chef]
tags: [devops, chef]
---


Vagrant is a fantastic tool for managing virtual machines and, for developers, it offers a great way to build you environments. One of my favourite features of Vagrant is that you can provision the VM with a variety of tools including Puppet, Chef and shell scripts. In this tutorial I'm going to show you how to provision a VM with a chef-solo and Berkshelf. The goal is a simple development environment for PHP that can be easily rebuilt at a moments notice.

Chef and Berkshelf
------------------

Vagrant offers a number of provisioning tools that we could use and over the years I have worked with most of them. I think Chef is one of the easiest to use for managing a development environment because it offers such a rich set of libraries for us to use. The code is written in Ruby so as long as you have a basic grasp of the syntax you should be able write some simple Chef recipes for your environment.

{% include ad-top-text.html %}

The feature of Chef that makes it a real winner for me is it's dependency management system [Berkshelf](http://berkshelf.com/). As a developer I don't want to spend a long time customising my environment, I want to use as many open source libraries as I can to speed up the process and let me focus on my work. Fortunately Chef has a fantastic selection of open source recipes for you to choose from. The main source is the [Chef Supermarket](https://supermarket.chef.io/) where you can find a recipe for most common tasks and, thanks to Berkshelf installing, them really easy.

The setup
---------

I'm going to assume you have Vagrant installed and but if not then head over to [Vagrant](https://www.vagrantup.com/ "Vagrant") and install it. You will also need to have the ChefDK installed to give yourself access to the tools we need. There is an installer available for most operating systems so just download it and run the install.

Chef is available out the box with Vagrant but we will need to install a plugin to use Berkshelf, just run:

	$ vagrant plugin install vagrant-berkshelf

Once the install is complete we will need to edit our Vagrantfile. Here is my Vagrantfile:

```ruby
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.berkshelf.enabled = true

  config.vm.provision :chef_solo do |chef|
  end
end
```

As you can see I have changed the base box to use Ubuntu 14.04 and enabled the Berkshelf plugin. I have also added  a provisioning section to configure chef-solo.

Provision with Chef
-------------------

When Vagrant provisions the VM with Chef it will look for recipes in Berkshelf and a directory called `cookbooks`. You can override this location but for this tutorial we'll leave it as the default. Make a directory called `cookbooks` and `cd` into it.

I like to set up a cookbook for my virtual machine and use that to resolve my dependencies. If you only need third party recipes you could just have a Berksfile but I think it's helpful to have a cookbook in case there are extra things you need to do. I'm going to call my cookbook dev because it is my development environment but you can call it whatever you like, if you plan to have more than one then name it something clear. To create the cookbook run:

	$ berks cookbook dev

This will create a dev directory with a template cookbook inside.

Adding libraries
----------------

The goal of this project to is set up an automated virtual machine with as little work as possible so I'm not going to write any code if there are recipes available. To get started I'm going to add PHP to my VM.

In Chef Supermarket find the [Chef PHP library](https://supermarket.chef.io/cookbooks/php), the one I'm using has more than 29 million downloads so it's clearly been well tested. Copy the Berkshelf line and paste it into `cookbooks/Dev/Berksfile`. The file should look like this

```ruby
source "https://supermarket.chef.io"

metadata
cookbook 'php', '~> 1.5.0'
```

That is everything you need to do import the recipe to use in your virtual machine.

{% include googleAd.html %}

The Vagrantfile
----------------

The final step is to add the PHP recipe to your Chef run list. The run list is exactly as it sounds, it is a list of recipes for Chef to run. Below is the entire Vagrantfile and as you can see it has an array of recipes which include PHP.

```ruby
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.berkshelf.enabled = true
  config.berkshelf.berksfile_path = "./cookbooks/dev/Berksfile"

  config.vm.provision :chef_solo do |chef|
  chef.run_list = [
    'recipe[php]'
  ]

  end
end
```

{% include ad-bottom-text.html %}

I have set the location of the Berksfile because I want use the one in my recipe.

The final step is to run `vagrant up` and you should see Chef running on your VM. Once it is complete you can do `vagrant ssh` and `php -v` to see that PHP has been installed by Chef.

The next step is to add more features to your virtual machine by locating recipes in Chef Supermarket and loading them in the same way.

##  Some useful links

* [Chef](https://www.chef.io/)
* [Berkshelf](http://berkshelf.com/)
* [Vagrant with Chef documentation](https://docs.vagrantup.com/v2/provisioning/chef_solo.html)
