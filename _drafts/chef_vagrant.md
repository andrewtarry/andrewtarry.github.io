Provisioning Vagant with Chef

Vagrant is a fantastic tool for managing virtual machines and, for developers, it offers a great way to manage you environments. One of my favorate features of Vagrant is that you can provision the VM with a varity of tools including Puppet, Chef and shell scripts. In this tutorial I'm going to show you how to provision a VM with a chef-solo and Berkshelf. The goal is a simple development environment for PHP that can be easily rebuilt at a moments notice.

Chef and Berkshelf

Vagrant offers a number of provisioning tools that we could use and over the years I have worked with most of them. I think Chef is one of the easiest to use for managing Vagrant virtual machines because it offers such a rich set of libraries for us to use. The code is written in Ruby so as long as you have a basic grasp of the syntax you should be able write some simple Chef recipes for your environment.

The feature of Chef that makes it a real winner for me is it's dependency management system Berkshelf. As a developer I don't want to spend a long time customising my environment, I want to use as many open source libraries as I can to speed up the process and let me focus on my work. Fortunatly Chef has a fantastic selection of open source recipies for you to choose from. The main source is the [Chef Supermarket](https://supermarket.chef.io) where you can find a recipe for most common tasks and, thanks to Berkshelf installing, them really easy.

The setup 

I'm going to assume you have Vagrant installed and but if not then head over to [Vagrant](http://vagrantup.com "Vagrant") and install it. You will also need to have the ChefDK installed to give yourself access to the tools we need. There is an installer availble for most operating systems so just download it and run the install.

Chef is availble out the box with Vagrant but we will need to install a plugin to use Berkshelf, just run:

	$ vagrant plugin install vagrant-berkshelf
	
Once the install is complete we will need to edit our Vagrantfile. Here is my Vagrantfile:

	VAGRANTFILE
	
As you can see I have changed the base box to use Ubuntu 14.04 and enabled the Berkshelf plugin. I have also added  a provisioning section to configure chef-solo. 

Provision with Chef

When Vagrant provisions the VM with Chef it will look for recipes in Berkshelf and a directory called `cookbooks`. You can override this location but for this tutorial we'll leave it as the default. To set up make a directory called `cookbooks` and `cd` into it. 

I like to set up a cookbook for my virtual machine and use that to resolve my dependencies. If you only need third party recipes you could just have a Berksfile but I think it's helpful to have a cookbook in case there are extra things you need to do. I'm going to call my cookbook dev because it is my development environment but you can call it whatever you like, if you plan to have more than one then name it something clear. To create the cookbook run:

	$ berks cookbook dev

This will create a dev directory with a template cookbook inside. 

Adding libraries

The goal of this project to is set up a recreatable virtual machine with as little work as possible so we are not going to write our own code if there are recipies available. To get started I'm going to add PHP to my VM. 

In Chef Supermarket find the [Chef PHP library](LINK), the one I'm using has more than XXX downloads so it's clearly been well tested. Copy the Berkshelf line and paste it into `cookbooks/Dev/Berksfile`. That is everything you need to do import the recipe to use in your virtual machine.

The Vagrantfile

The final step is to add the PHP recipe to your Chef run list. The run list is exactly as it sounds, it is a list of recipes for Chef to run. Below is the entire Vagrantfile and as you can see it has an array of recipes which include PHP.

	VAGRANTFILE
	
I have set the location of the Berksfile because I want use the one in my recipe. You could just have a Berksfile and skip the recipe but I find it useful to have somewhere to add your own code, even when you are trying not to.

The final step is to run `vagrant up` and you should see Chef running on your VM. Once it is complete you can do `vagrant ssh` and `php -v` to see that PHP has been installed by Chef.

The next step is to add more features to your virtual machine by locating recipes in Chef Supermarket and loading them in the same way.

Some useful links

* Example code
* Chef
* Berkshelf
* Vagrant with Chef documentation