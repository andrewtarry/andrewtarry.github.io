---
layout: post
title: Deserializing an interface with Jackson
description: Using Java and json together can make it hard to manage deserialisation correctly when using interfaces. Here we show the solution to 3 common scenarios
date: 2020-05-27 14:10:00 +0000
categories: [Tutorial, Java]
tags: [java, jackson, json]
---

Jackson is my favourite library for mapping Json to a Java object and most of the time it can map your objects to a POJO but when using interfaces it takes a bit more work.
Jackson would normally read the types from the POJO that you attempt to use but when an interface is used at the type the problems arise Jackson cannot find the implementation on its own. 

In the examples below I want to show how we can deserialize a simple json body into a POJO. The json body is:

```json
{
  "myInterface": {
    "a": "Z",
    "b": "Y"
  }
}
```

{% include ad-top-text.html %}

Our target POJO looks like this:

```java
public class MyPojo {

    private MyInterface myInterface;

    // getters and setters
}
```

The `MyInterface` type is simply has some getters

```java
public interface MyInterface {

    String getA();

    String getB();
}
```

The example is fairly contrived but it demonstrates a common problem, that you need to tell Jackson how to handle your interface and which implementation to use.

## Scenario 1: when you control the interface and there is only one implementation

This is one of the most simple scenarios because there is only one possible implementation of the interface. In this case you are using the interface to avoid tightly coupling the interface to the implementation but you can be sure there will not be a need to use multiple implementations.

Using this approach we can annotate the interface to tell Jackson how to deserialise it.

```java
package com.andrewtarry.jackson.single;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;

@JsonDeserialize(as = MyInterfaceImpl.class)
public interface MyInterface {

    String getA();

    String getB();
}
```

This tells Jackson to deserialise to an instance of the `MyInterfaceImpl` class (as long as `MyInterfaceImpl` implements `MyInterface`). 

{% include googleAd.html %}

## Scenario 2: when you control the interface and there is more than one implementation

Things get a little more complex when there we need to introduce polymorphism into the code base. If we need to support multiple implementations we need to have a way for Jackson to know which implementation to use.

```java

package com.andrewtarry.jackson.multiple;

import com.fasterxml.jackson.annotation.JsonSubTypes;
import com.fasterxml.jackson.annotation.JsonTypeInfo;

@JsonTypeInfo(
        use = JsonTypeInfo.Id.NAME,
        include = JsonTypeInfo.As.PROPERTY,
        property = "type",
        defaultImpl = MyInterfaceImpl.class
)
@JsonSubTypes({
        @JsonSubTypes.Type(value = MyInterfaceImpl.class, name = "standard"),
        @JsonSubTypes.Type(value = MyOtherInterfaceImpl.class, name = "other")
})
public interface MyInterface {

    String getA();

    String getB();
}
```
To support multiple implementations we need to use the `@JsonSubTypes` annotation. Using this annotation we have configured Jackson to read the `type` property from the json body and use that to select the correct implementation.

The advantage of this is that we can control the implementation easily but we are not exposing details of our deserialisation logic into the API. The JSON body will need to look like this.

```json
{
  "myInterface": {
    "a": "Z",
    "b": "Y",
    "type": "other"
  }
} 
```

The `type` value is only used by Jackson so needing to include it in the API may feel like a poor solution. Given that different implementations will have an impact on the outcome of the API call we might be asking a lot of our users to set the correct type. 

This approach might work if your API is internal or the `type` property is an existing, well understood value but I would argue that for external API’s it might not be right approach.

## Scenario 3: when you do not control the interface

The other possibility is that you do not have the option to add annotations. It might be that you need to deserialise to a POJO that’s managed but a third party and introducing annotations is not possible. For this we need to look at custom code.

Jackson allows us to use a custom deserializer to we can return any type of data without needing annotations. 

```java
package com.andrewtarry.jackson.custom;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.deser.std.StdDeserializer;

import java.io.IOException;

public class MyInterfaceDeserialize extends StdDeserializer<MyInterface> {

    public MyInterfaceDeserialize() {
        this(null);
    }

    protected MyInterfaceDeserialize(Class<?> vc) {
        super(vc);
    }

    @Override
    public MyInterface deserialize(JsonParser p, DeserializationContext ctxt) throws IOException, JsonProcessingException {
        JsonNode node = p.readValueAsTree();
        String a = node.get("a").asText();
        String b = node.get("b").asText();

        MyInterfaceImpl impl = new MyInterfaceImpl();
        impl.setA(a);
        impl.setB(b);

        return impl;
    }
}
```

{% include ad-bottom-text.html %}

We need to register this deserializer with Jackson.

```java
SimpleModule deserialization = new SimpleModule();
deserialization.addDeserializer(MyInterface.class, new MyInterfaceDeserialize());

objectMapper.registerModule(deserialization);
```
Now whenever Jackson needs to handle an instance of `MyInterface` it will use the custom deserializer. Using this method we could decouple the code from the json body completely as well as parse data types that would otherwise be impossible. We could even be returning an anonymous class here and not create an implementation at all if we wanted to.

The downside is that we need to write more code with will become complex in a large project. My view is that custom deserialisation is a last resort, we should try to use annotations and keep the project simple and use custom code to solve problems that we cannot do another way.

## Conclusion

Using Java and json can be difficult since one requires strong typing and predefined data structure but the other allows  massive amounts of flexibility. The way to handle that will differ for different projects but here I want to present a few options on how to manage json while using Java interfaces. 

API design should not depend on the implementation technology and the best practices of interfaces and polymorphism in Java should not be abandoned into order to use an API. Here are a couple of options on how to handle Jackson when the API and Java code are not perfectly aligned. 