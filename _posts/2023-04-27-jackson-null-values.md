---
layout: post
title: How to handle null with Jackson
description: Jackson is a powerfull library and it has a number of ways to handle null. The way you handle null will be important to your API design and Jackson can support your choice in a number of ways
date: 2023-04-27 04:10:00 +0000
categories: [Tutorial, Java, Jackson]
tags: [java, jackson, json]
og_image: /assets/img/emptysheet/emptysheet_wide.jpg
image: /assets/img/emptysheet/emptysheet.jpg
---

Null is one of the most problematic concepts in software development. It means that a variable has no value. It is not the same as false or 0, it simply means nothing.

Handling `null` correctly is always a challenge. Every developer has faced a `NullPointerException` and needs to check if values are `null` before they can call the methods. 

In JSON, `null` is a literal and can be used in objects to identify variables without a value.

{% include ad-top-text.html %}

## Should you include null in an API payload?

You have two options in your API design. You could include `null`:

```json
{
  "name": "Bob Smith",
  "title": "Mr"
}
```

Or exclude null:

```json
{
  "name": "Bob Smith"
}
```

If you include `null`, then the consumers of your API will have a consistent set of keys but will need to handle the times that the value is `null`. If you exclude keys the payload will be smaller but the consumers will need to handle keys not being sent.

The impact of the choice depends on the language and how objects are deserialised. Since you probably will not know every consumer you will ever have, you cannot judge it based on the language and library. 

I normally like to send a `null` value, that way, the keys are consistent, but it’s a design choice. Pick one approach and stick with it.

## How Jackson Handles Null

If you are using Jackson there are a number of options for handling `null` values.

This example class is a basic customer that we will be mapping to Json.

```java
public class Customer {

    private final String name;
    private final String title;

    public Customer(String name, String title) {
        this.name = name;
        this.title = title;
    }

    public String getName() {
        return name;
    }

    public String getTitle() {
        return title;
    }
}
```

Our object mapper will use all the defaults.

```java
BasicExample example = new BasicExample("Bob Smith", "Mr");
ObjectMapper objectMapper = new ObjectMapper();

System.out.println(objectMapper.writeValueAsString(example));
```

The resulting Json is:

```json
{"name": "Bob Smith", "title": "Mr"}
```

This is expected but what if we make one of the values `null`:

```java
BasicExample example = new BasicExample("Bob Smith", null);
ObjectMapper objectMapper = new ObjectMapper();

System.out.println(objectMapper.writeValueAsString(example));
```

Now we get:

```json
{"name": "Bob Smith", "title": null}
```

This might be fine for your use case. Every value that is set as `null` be returned in the Json body.

## Excluding Null with Jackson

If you want to remove `null` values from the object there are a couple of options. The best option is to set the value globally on the object mapper.

```java
objectMapper.setSerializationInclusion(JsonInclude.Include.NON_NULL);
```

Now the output will be like this.

```json
{"name": "Bob Smith"}
```

If you are using Spring Boot you can also set this in the properties file:

```yaml
spring:
  jackson:
    default-property-inclusion: non_null
```

{% include ad-bottom-text.html %}

## Using annotations

Another option is to use an annotation on the class or the property to achieve the same result. 

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public class Customer {

    private final String name;
    private final String title;

    public Customer(String name, String title) {
        this.name = name;
        this.title = title;
    }

    public String getName() {
        return name;
    }

    public String getTitle() {
        return title;
    }
}
```

This will allow you greater control over the content of the API but it will risk inconsistency in the handling of `null` values. If you apply the annotation to individual properties the API will become difficult for users as they will need to check for the key and if the value is `null`.

## Conclusion

How you handle null is a design decision. Jackson has several ways to include or exclude `null` if you need to. To make you API easy to use I recommend either always including `null` values or always excluding them, just make it consistent. 
