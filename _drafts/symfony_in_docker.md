Docker provides an extremly flexible way to package and deploy a Symfony 2 application. This guild will help you get an application running in a container so it can be deployed to any environment that supports Docker.

Installing Docker

Getting Docker installed depends your environment, Linux users can run Docker natively but Mac or Windows users will need to install docker-machine. All of the installation instructions for your environment can be found on the [Docker Website](https://docs.docker.com/installation/).

Configuring your application

To get started with Docker you first need to add a `Dockerfile` to the root of your application.

```
#Dockerfile
FROM php:5.6-apache

RUN apt-get update \
  && apt-get install -y libicu-dev \
  && docker-php-ext-install intl mbstring \
  && a2enmod rewrite

COPY app/php.ini /usr/local/etc/php/
COPY app/apache2.conf /etc/apache2/apache2.conf
COPY ./ /var/www/html/

RUN chown -R www-data:www-data /var/www/html/app/cache /var/www/html/app/logs
```

This basic `Dockerfile` sets up everything is needed for a Symfony 2 application. There is a lot of documentation available for this file from [Docker](https://docs.docker.com/reference/builder/).

The docker image is based on the offical PHP 5.6 image and it comes with Apache installed. The first run block will install the PHP intl and mbstring extensions that are used by Symfony. Then the Apache rewrite module is enabled.

Configuring PHP

Once of the biggest advantages that Docker provides is an isolated environment for an application. In the next line of the file we are running `COPY app/php.ini /usr/local/etc/php/`. This will copy a `php.ini` from the app directory in your application. A template file can be found in the [PHP Repository](https://github.com/php/php-src/blob/master/php.ini-production).

The `php.ini` can be tailored to the application but make sure you set the `date.timezone` to your locale.

Configuring Apache

Apache can be configured in the same way as php so you can put an Apache configuration file in your project. In the docker container you will only be running a single application so there is no need for virtual hosts. Here is an example Apache 2 configuration file

```
User www-data
Group www-data
ErrorLog /proc/self/fd/2

IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf

Listen 80
DocumentRoot /var/www/html/web
<Directory /var/www/html/web>
    AllowOverride None
    Order Allow,Deny
    Allow from All

    <IfModule mod_rewrite.c>
        Options -MultiViews
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ app.php [QSA,L]
    </IfModule>
</Directory>

AccessFileName .htaccess
<FilesMatch "^\.ht">
	Require all denied
</FilesMatch>

<FilesMatch \.php$>
	SetHandler application/x-httpd-php
</FilesMatch>

DirectoryIndex disabled
DirectoryIndex app.php
```

This is a basic Apache 2 configuration file that will be added to the container.

Adding your application

The final parts of the `Dockerfile` copy the application to `/var/www/html` within the container before running chmod on the logs and cache directories.

Building the container

Once all the files are in place the container can be built by running `docker run -t myname\symfony_apps:latest .`. This will build the container
