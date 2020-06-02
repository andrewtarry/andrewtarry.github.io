---
layout: post
title: Symfony 2 on Heroku
description: Hosting Symfony 2 apps on Heroku is easy and useful but there are a steps to take before deploying
date: 2014-10-14 14:10:00 +0000
categories: [PHP, Symfony]
tags: [phy symfony]
---

Since Heroku started supporting PHP it has become a valuable hosting option for Symfony apps. It offers a nice middle ground between the lack of control you get with shared hosting and the workload of hosting the site yourself with AWS or Rackspace. Heroku offers managed hosting so it's less for you to worry about but it offers the flexibility changing PHP extensions and using plugins. It is not as flexible as a service like AWS but the work is a lot less and I have found their support to be very good when you have a problem.

## Deploying Symfony

There is some good documentation available on running [PHP on Heroku](https://devcenter.heroku.com/articles/getting-started-with-PHP#introduction) so I don't intend on repeating that here. I will assume you have followed the steps in the introduction and you have your app that you want to deploy.

### Setting your dependencies

Heroku uses composer not only to install your PHP dependencies but also to set up your PHP version and extensions. Normally composer would just give you an error if the extensions or version does not match the system but Heroku will actually install them for you. This is great because you can really customise the environment but you need to be careful about actually listing the dependencies on your system. 

You can see the extensions that you have on your current system with:

	$ composer show --platform
	
The extensions that your application needs should then be added to you composer.json.

```json
"require": {
    "PHP": "~5.5",

    "ext-gd": "*",
    "ext-curl": "*",
    "ext-intl": "*",
    "ext-json": "*",
    "ext-mbstring": "*",
    "ext-PDO": "*",
    "ext-soap": "*"    
}
```
        
Heroku will install all the extensions and the runtime that you need. Details of the [supported packages are available from Heroku](https://devcenter.heroku.com/articles/PHP-support).

{% include googleAd.html %}

### Servers

As you would expect Heroku supports both Nginx and Apache, using PHP-fpm which is always installed. Setting up the web server correctly requires some configuration but it's fairly simple.

First you should add the Heroku build pack to you application with

	$ composer require heroku/heroku-buildpack-PHP:*
	
If you are like me and have set the config bin directory in composer then all the interesting files will be your bin directory. Most of the documentation will use the default path in the vendors directory so remember that it is likely not to be the case in Symfony.

To set up Nginx I added a configuration file to the project that will be deployment when I push my app.

```nginx
location / {
    # try to serve file directly, fallback to rewrite
    try_files $uri @rewriteapp;
}

location @rewriteapp {
    # rewrite all to app.PHP
    rewrite ^(.*)$ /app.PHP/$1 last;
}

location ~ ^/(app|app_dev|config)\.PHP(/|$) {
    fastcgi_pass heroku-fcgi;
    fastcgi_split_path_info ^(.+\.PHP)(/.*)$;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param HTTPS off;
}
```

This is basically a default Symfony 2 Nginx file but with a few Heroku variables. These will be replaced for you by the deployment system so don't worry about them. The fastcgi pass will always be `heroku-fcgi`. Remember not to wrap this with a `server` tag because it will not work correctly.

Finally you will need to add you `Procfile` so Heroku knows what to do. This has to be in the root of your project in a file called `Procfile`.

	web: bin/heroku-PHP-nginx -C <path to nginx conf file> <path to web dir - normally web/>
	
Heroku will now set up your application with Nginx.

### MySQL

When you first go on to Heroku you will notice PostgreSQL is the default database option. I do not intend to cover the choice between MySQL and PostgreSQL here but for many developers MySQL is the standard. If you are starting a new project then it might be worth thinking about PostgreSQL but you want to stick to MySQL then there are options. The easy option is ClearDB which can be found under the Heroku add-ons. The documentation is clear and you should be up and running in no time.

You will need to extract usernames and passwords from the Heroku configuration in the terminal so it can be a little unclear when you first use ClearDB but you can connect to it as normal. Follow the documentation and it should work like any other MySQL database.

Alternative is host the database seperatly with something like AWS RDS. This might be an option if you have fairly advanced database needs but could be overkill for most projects.

### Package.json

When I build Symfony 2 apps I normally like to build my frontend assets with Grunt rather than assetic. The result is that I will normally have a `package.json` file in the root of my application to handle my node modules. This can confuse the Heroku build system because it will think you have a node.js application and configure the environment for that. The result is that you will get a lot of 500's from your application.

To solve this problem you need to tell Heroku to use the PHP build system rather than the node.js one. To do this you can run this command from the root of the project.

	$ heroku config:set BUILDPACK_URL=https://github.com/heroku/heroku-buildpack-PHP
	
Heroku will now always build your app with PHP rather than node.

{% include googleAd.html %}

### Composer Scripts

This is one to be careful about. When Heroku builds your app it does a `composer install` and so it will trigger the composer events listed in your composer.json. Symfony has a number of events list up to do useful things like clear the cache, build the parameters.yml and build the bootstrap files. While these are useful they can cause problems because they will always run in the dev environment rather than prod. At the time of writing there is an open [Github](https://github.com/symfony/symfony/issues/11704) issue about this with some suggestions but there is not a perfect solution.

The likely result is that the deployment will fail due to the database not being there. This can be caused by the `config_dev.yml` listing a different database that the `config.yml`. Unfortunately this will prevent the build from completing and cause the deployment to fail. To avoid it I recommend not to override too much in `config_dev.yml` and remove composer scripts you don't really need. If you need additional local environments just add new config files and front controllers but call them something other that dev to avoid the issue. Hopefully it will be solved soon but it's fairly easy to work around.

## Happy deploying

Heroku offers a really nice and simple hosting option for Symfony that's powerful enough for most applications. It has a few gotchas that come with the build system but once your first app is running you should have no problems.  