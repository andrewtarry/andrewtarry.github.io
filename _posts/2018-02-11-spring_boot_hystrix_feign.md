---
layout: post
title: Spring Boot, Feign, Ribbon and Hystrix
description: Setting up Feign, Ribbon and Hystrix with Spring Boot
date: 2018-02-11 14:10:00 +0000
categories: [Java, Spring Boot]
tags: [java, spring boot]
---

Using Spring Boot with the Netfix OSS toolset is easy thanks to some excellent integration libraries. In a modern microservice based application it has become even more important to handle downstream failures properly and Netflix have provided a particularly neat solution for that.

All of the source code for this post can be found on [Github](https://github.com/andrewtarry/spring-boot-feign-ribbon-hystrix)

First let's cover what each component does in this application. In this tutorial I'm going to leave Eureka out, it would often be used for application discovery but its not always easy to add to an existing application.

* **[Feign](https://github.com/OpenFeign/feign)** - HTTP client library for integrating with REST services
* **[Ribbon](https://github.com/Netflix/ribbon)** - Load balancing, fault tolerant HTTP client
* **[Hystrix](https://github.com/Netflix/Hystrix)** - Latency and fault tolerance library that will provide a circuit breaker to help with external failures.

Lets imagine we need to build an application that has to interact with a list of products from another application. The list of products is managed by another team (or maybe another company) so don't know anything about how it works and can't change it. Here's a simplified json body on what to expect. 

```json
{
  "products": [
    {
      "id": "173892742",
      "title": "Product name",
      "description": "Product description",
      "price": 19.99
    },
    {
      "id": "48932472",
      "title": "Another product name",
      "description": "Another product description",
      "price": 34.99
    }
  ]
}
```

In real life this would API would have a lot more data and some search criteria but it really doesn't matter for our purposes.

## The pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.andrewtarry</groupId>
    <artifactId>example</artifactId>
    <version>0.1.0</version>
    
    <properties>
        <java.version>1.8</java.version>
    </properties>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>1.5.10.RELEASE</version>
    </parent>
    
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>Edgware.SR1</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-feign</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-hystrix</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-ribbon</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

So in our pom we first set our up dependency management with the parent project as the Spring Boot starter parent and add the Edgware release as a dependency set. Our list of dependencies is small and only includes the web package, feign, hystrix and ribbon.

## The Application Class

```java
package com.andrewtarry.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@EnableFeignClients
class ExampleApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(ExampleApplication.class, args);
    }
}

```

The main class is fairly simple, just a standard Spring Boot main method but with the addition of the `@EnableFeignClients` annotation. This will allow Spring Boot to scan for Feign clients.

{% include googleAd.html %}

## The Client

```java
package com.andrewtarry.example;

import com.andrewtarry.example.model.ProductList;
import org.springframework.cloud.netflix.feign.FeignClient;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@FeignClient(name = "products", fallback = ProductRequestFallback.class)
public interface ProductRequest {

    @RequestMapping(method = RequestMethod.GET, path = "/products")
    ProductList getProducts();
}

```

The client is an interface that will be implemented by Spring thanks to the `@FeignClient` annotation. That will cause the client to be created and name becomes the configuration key so you can set the servers. The Feign client will not be able to be autowired into any service that needs it.

## The Fallback

The real benefit of using the Hystrix is the option to use a fallback. When a fallback is configured the application will be able to proceed, with a more basic response even if the other service is down.

```java
package com.andrewtarry.example;

import com.andrewtarry.example.model.ProductList;

/**
 * Fallback for the product request, get an empty list
 */
public class ProductRequestFallback implements ProductRequest {

    @Override
    public ProductList getProducts() {
        return new ProductList();
    }
}

```

In the fallback we simply return an empty list of products but in a real scenario this could be pulled from a cache or simply include the most popular products.

## The Configuration

Since we're not using Eureka in this example the url of the servers we want to send requests to need to be put into configuration. This can be a useful technique when the service you need to interact with is outside of your control.

```yaml
eureka:
    enabled: false

ribbon:
    products:
      listOfServers: api1.example.com,api2.example.com

feign:
  hystrix:
    enabled: true
```

The configuration has firstly disabled Eureka, this should be option but if Eureka is on the classpath it will interfere with ribbon configuration so its best to be explicit.

The ribbon configuration uses the name of the Feign client, in this case `products` so ribbon knows which client to apply it to.

## Conclusion

There you have it, an application that includes a client side load balancer and a circuit breaker to provide fault tolerance. Spring Boot does most of the hard work for us so we just need to configure it.

