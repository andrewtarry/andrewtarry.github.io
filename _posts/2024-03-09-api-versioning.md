---
layout: post
title: API Versioning - the good, the bad and ugly
description: API Versioning is something we all need to handle but no one really likes. Here are a 4 options of how to version your API
date: 2024-02-19 01:10:00 +0000
categories: [API, Architecture]
tags: [API]
---

![Crossroads](/assets/img/crossroads.jpg)

API versioning is a fact of life and something that everyone has to deal with at some point. There are several ways to version an API, and it tends to cause some debate whenever it comes up.

Typically, teams create a new version of the API when something changes, and they need to add, remove, or restructure fields. They will keep the old version running for a while and ask consumers to kindly migrate but a certain date.

Here, we will consider all the options and decide which is best.

Our opions are:

1. Don't version
2. Use the path
3. Use the content-type
4. Use a header

They all have their pros and cons so which one should you use?

## Option 1 - Don’t version

There are groups of people who will argue that versioning is fundamentally the wrong approach. The argument goes that you are probably versioning the API because there are some new mandatory fields, but you don’t want to break the existing consumers. That seems reasonable, but if the new fields are truly mandatory, how can you support a version of the API without them?

I’ve always liked this argument: if you are making a new version, you must have a good reason. Think about why you are making the new version.

- Are you doing it because of a change to a downstream system?
- Is it due to a legal change?
- Is there some major business change that has forced this upon you?

These are all fine reasons to create a new API version, but how will you support the old version? The change cannot be that fundamental if the old API version can still work.

{% include ad-top-text.html %}

The idea is to add the new fields as optional to the existing API and code it to handle situations when they are not sent. This has the same effect as versioning; there are new fields, but the consumers do not have to use them until they’re ready.

This is all fine in theory, but it can be more difficult in practice. Often, there is a vital change within the business, and the old API will have to be stopped. A new version will be released, and the old version will have a shutdown date. The business might be able to accept clients on older API versions for a while, but they would need to force the change eventually. This is even more common for internal APIs or small user groups. If you know all the consumers, you can force a migration.

As much as I like the idea of refusing to version, often there are good reasons to do it. Good senior engineers should always push back and handle it another way just saying no is often unrealistic.

## Option 2 - Version in the path

This is one of the most common approaches, but it seems to get some people upset.

The idea is to construct the URL with a version number that can offer various levels of specificity depending on the API and the client's needs. For example:

```
/api/v1/product

/api/v2/product

/api/v2.3/product
```

Each of these APIs has a different path, and the consumer can select the version they want to use. The problem is that this RESTful URL should deal with nouns. This version number breaks that concept and forces the consumer to think about the technical details of the data. Even Roy Fielding, the original creator of REST, described it as “a middle finger to your API consumers”.

I understand this frustration. Putting the version in the URL is an ugly approach that causes problems. It also makes it harder for consumers to know the latest version and which they can use. Image these scenarios:

- The API contains likes; if they request v2, will the links all go to a v2 API?
- If the APIs do not all change versions simultaneously, the links might be split between the two versions. Then you change the links later, is that a breaking change to the API containing links?
- Is there a way for consumers to call the latest version of the API without having to know the version number?

This solution can be clear and easy to implement but introduces a structure to the API design you might not want. A change to the version might have to be implemented across all the clients, and you don’t get the clean, RESTful structure you might want.

## Option 3 - Query parameters

This approach is also simple, and it avoids the need for changes to the URL structure. Here we just add a version to the end of the query.

```
/product?version=v2.3
```

It is simple to understand, but it does have a few drawbacks.

1. You need to decide what the default version is. Eventually, you will need to change the default, and that will break all the clients not sending a version.
2. Query parameters are also not common for non-GET-based requests. There’s nothing wrong with them, but most APIs that send data will not also use a query string.
3. Routing will be harder than having the version in the path. A reverse proxy or routing rule can easily send traffic to the right target if the version is in the path, but query parameters are rare.

I find that versions in the query can be useful for testing internally, but I would avoid them in production for a public API.

## Option 3 - Content negotiation

This is one of the cleanest ways of handling versions. It avoids any issues with the path and uses the Accept header to get the version you need.

```
Accept: application/vnd.example.v1+json

Accept: application/vnd.example+json;version=1.0
```

The version can be part of the type or added to the end. Using this approach, the path and query string will not need to change, and the content type will describe what the client is looking for, which is the point of the Accept header in the first place.

There are some great examples of this in action, see the Github API as a prime example of Accept headers with versions. Their API is massive and used by many clients, all with content negotiation in the Accept header.

{% include ad-bottom-text.html %}

This seems like a good approach but what are the downsides, here are a few:

1. The version is obvious without looking at the code. You will get a different response on the same URL, and it can be easy to miss that you are using the wrong header.
2. Some tools might need to handle custom content types better. This can be an issue if you use some low-code tools that do not allow this customisation. I don’t see this as a major problem, the issue is the limitation of low-code tools. In a future article, I will discuss why low-code tools are a bad idea, but it is something to consider if you have a lot of low-code clients.
3. Consider what will happen if you receive a request with the Accept header of application/json. Should that return an error or a default version?

Overall, content negotiation strikes a good balance between being clean and powerful.

## Option 4 - Custom headers

Instead of using the Accept header, why not use a custom header that has no other purpose? The advantage is that you do not need to add any complexity to an existing header. You can add a header like this:

```
My-App-Version: v2.3
```

This approach has the same basic benefits as content negotiation but with the added benefit that your API can use the standard application/JSON content type. This does have a disadvantage, too; what will happen if the consumer fails to send the version header?

Overall, I think this approach is less helpful than content negotiation because you now have two headers to send: the Accept header and the version. You will still need to deal with systems that cannot send custom headers and the possibility of no version being sent.

## Conclusion - Which one should I use?

There is no right or wrong answer when it comes to versioning. In an ideal world, we would avoid it altogether, but eventually, you will have to version. My advice is to pick one approach and stick with it. If you are consistent, then you should be ok.

If I design an API from scratch, I normally look to content negotiation as my preference overall. However, some clients make that impractical, so I reach for path-based versioning while feeling unhappy about it.