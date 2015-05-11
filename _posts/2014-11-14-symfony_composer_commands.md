---
layout: post
title: Symfony Default Composer Scripts
description: Symfony has a number of composer scripts by default. Find out what they do
---

Have you ever wanted to know what all the composer scripts in the default Symfony composer.json do? No? I didn't think so but nonetheless, lets have a look at them.

As of Symfony 2.5 there are 5 commands in the default composer.json and most of them are inside the Sensio DistributionBundle Script Handler class. 

##buildBootstrap

The `ScriptHandler::buildBootstrap` command is required to build the `app/bootstrap.php.cache` file. The bootstrap file is neccissary for Symfony to correctly start. It is generated for you and the best thing to do is leave it alone to do it's job.

##clearCache

The clear cache command will simply run `app/console cache:clear`, possibly with the `--no-warmup` flag depending on your configuration. This can be useful to make sure your cache is not referencing out of date dependencies. If you remove this line from the composer.json your application will still work but remember to clear the cache manually.

##installAssets

Install assets is another example of a command that simply runs a console command. In this case the `app/console assets:install` command, unsurprisingly. If you are not using assets in your application then feel free to remove this line.

##installRequirementsFile

The install requirements file is there to create the `web/config.php` command and the `app/SymfonyRequirements.php` files. They are useful for checking your system for Symfony dependencies but are not essential for running your application. As the requirements files are updated for you it might be useful to check it if the system requriements change but it can be removed if you want to.

##removeSymfonyStandardFiles

This command removes the `app/SymfonyStandard` directory if it exists. This command is only relevent in some installation scearios and can be safely removed.

##Incenteev\\ParameterHandler\\ScriptHandler::buildParameters

This is the only command not in the Sensio Distrubution Bundle. This is the command that converts the `app/config/parameters.yml.template` into the `app/config/parameters.yml` file. A very useful command if you want to follow that workflow but not essential if you have taken a different approch.

Hope that all helps but please comment if you think I've missed something.
