---
layout: post
title: XML with Jackson
description: Jackson is a powerfull library that can handle XML or JSON using powerful mapping and annotations. XML may not be that common for new APIs but it remains a common technology that we need to deal with
date: 2023-05-12 04:10:00 +0000
categories: [Tutorial, Java, Jackson]
tags: [java, jackson, json, xml]
og_image: /assets/img/xml/xml-wide.jpg
image: /assets/img/xml/xml.jpg
---

Today most APIs and applications will use JSON. It’s easy and has become the standard data format. It wasn’t that long ago that XML was the standard, and it’s still around today. It might not be the format many people will choose to use for a new API, but there are still times when we need to consume XML data.

Fortunately, Jackson can handle XML in a very similar way to JSON, in fact, it was originally written for XML.

{% include ad-top-text.html %}

## Adding Jackson

First, add the dependencies. The XML library is an additional dependency in the newer versions of the Jackson.

```xml
<dependencies>
    <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-databind</artifactId>
        <version>2.13.0</version>
    </dependency>
    <dependency>
        <groupId>com.fasterxml.jackson.dataformat</groupId>
        <artifactId>jackson-dataformat-xml</artifactId>
        <version>2.13.0</version>
    </dependency>
</dependencies>
```

You can find the latest version in [Maven Central](https://central.sonatype.com/artifact/com.fasterxml.jackson.core/jackson-core/2.15.0)

## Create Your Data Model

In the previous [Jackson Article](/posts/jackson-null-values) we used this class as an example:

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

To use XML we need to use the Jackson XmlMapper instead of the ObjectMapper. From there most of the API is the same as if we were using JSON.

```java
BasicExample example = new BasicExample("Bob Smith", "Mr");
XmlMapper objectMapper = new XmlMapper();

System.out.println(objectMapper.writeValueAsString(example));
```

The resulting XML is:

```xml
<Customer>
    <name>Bob Smith</name>
    <title>Mr</title>
</Customer>
```

## Customising the XML output

This default serialisation can be adjusted with annotations just like if we using JSON. The confusing element is that Jackson uses the same annotations for XML, so the annotations often include Json in the name even when we are using XML.

Lets image the name property should be called `fullname`.

```java
public class Customer {

    @JsonProperty("fullname")
    private final String name;
    private final String title;

    // Constructor, getters and setters
}
```

Now the output XML includes the custom name we included. 

```xml
<Customer>
    <title>Mr</title>
    <fullname>Bob Smith</fullname>
</Customer>
```

## Changing the object name

What about if the object's name in the API does not match the Java class? This is not a problem in JSON because the JSON objects are anonymous but in XML we need to name the object. Fortunately, Jackson has a way to help with that.

Imagine there is a change in the business terminology. A `Customer` now has to be called a `Client`. We can change it with an annotation.

```java
@JacksonXmlRootElement(localName = "Client")
public class Customer {

    // Class content remains the same
}
```

Now the output is:

```xml
<Client>
    <title>Mr</title>
    <fullname>Bob Smith</fullname>
</Client>
```

Now the wrapper of our XML object has been customised. 

{% include ad-bottom-text.html %}

## Conclusion

Jackson is a powerful library that was originally designed for XML. Today it has become the standard tool for converting Java objects to JSON but it can be used for XML too. Using Jacksons annotations we can map to XML, including features that are not present that are not in JSON.