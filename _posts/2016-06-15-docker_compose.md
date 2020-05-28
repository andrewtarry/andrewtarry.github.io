---
layout: post
title: Using hostnames in docker compose
description: Using hostnames in docker compose
---


I've talked about [docker before](/symfony_in_docker) and I think it makes an extremely powerful part of the development toolchain. It gives you the ability to run a docker container locally and then deploy that same container to production. That's all well and good but production has things other than just your app, it's got a database, maybe a redis cache, perhaps some other internal services to talk to. So how do you replicate all of this in production?

One of the best tools in the docker ecosystem is [docker compose](https://docs.docker.com/compose/overview/). Back in the day it was originally named `fig` before it moved into docker world and renamed as docker compose. Many versions later it is a mature and useful tool for building you development environment. 

## Docker Compose yaml

Docker compose uses a configuration file which is, logically, called `docker-compose.yml`. 

```YAML
version: '2'
services:

  app:
    build: ./
    ports:
      - "8080:80"

  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: 'testpassword'
      POSTGRES_USER: app_user
      POSTGRES_DB: app
    ports:
      - "5600:5432"

  redis:
    image: redis

```

Here is a simple config file for an app that we might be building. We are using version 2 of the docker compose yaml format so we need to mention that at the top of the file. In version 2 each container is listed under the `services` section of the file. Here we have an app that's built from a `Dockerfile` in the current directory and that we want to see in on `localhost:8080`. In addition there's a database and redis that our app will need. The great thing is that there's no need to install anything locally because it will sit inside a container.

The app can communicate with the database or redis using the `db` and `redis` as their host names. 

{% include googleAd.html %}

## Being a bit cleaver with host names

One of the difficult things with simple host names is that they are rarely like that in a real environment, you might be dealing with `redis.internal.prod.example.com` rather than simply `redis`. You can get around this problem with different configuration files or environment variables but it would be even better if you had those real domain names that you could use. You might also find that production has several database servers but in development you only want to use one, so how can you handle multiple domains.

Fortunately docker compose provides a nice way to handle this.

```YAML
version: '2'
services:

  app:
    build: ./
    ports:
      - "8080:80"
    networks:
      - mynetwork
      
  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: 'testpassword'
      POSTGRES_USER: app_user
      POSTGRES_DB: app
    ports:
      - "5600:5432"
    networks:
      mynetwork:
        aliases:
          - db1.internal.prod.example.com
          - db2.internal.prod.example.com

  redis:
    image: redis
    networks:
      mynetwork:
        aliases:
          - redis.internal.prod.example.com


networks:
  mynetwork:
    driver: bridge
```

Now we have a new network creatively called `mynetwork` but it could be called anything. We're using the docker standard bridge network so it behaves in the way we are all used to with docker. The difference is that now the redis container has a real domain and the database has 2. Our application does not need to know it's running in development because all the domains are the same.

There is no longer a need to link containers manually, it's hard to do in a large cluster and domain names are just better.

## Signing off

This has been a quick intro to some of the benefits of docker compose compared to just starting containers. I have recently seen a few projects where people have written some cleaver scripts to start containers and link them all, in one case there was even `make` being used to start them. There is simply no need because docker provide docker compose to do this for you. 

It makes a great development environment and is the easiest way I've seen to develop with docker.
