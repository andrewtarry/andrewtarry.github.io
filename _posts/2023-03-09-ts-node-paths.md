---
layout: post
title: Shared library development with ts-node
description: Developing shared libaries with ts-node requires custom configuration to be added to the build so that libraries can be found. Here are the steps you need to take to set it up
date: 2023-03-09 01:10:00 +0000
categories: [Typescript]
tags: [ts-node, ts, typescript]
og_image: /assets/img/ts-node-paths/400w/node-paths.png
---

![Paths image](/assets/img/ts-node-paths/400w/node-paths.png)

When developing a large project, it can be useful to put some of the code into a shared library and use local file paths to load it. That can be harder than it sounds with Typescript so here I will share how I did it with much trial and error.

## Project set up

My project is fairly simple, but this approach will work if you have a more complex project with lots of libraries and applications.

```
ProjectRoot
 --> mylibrary
        --> package.json
        --> src/
 --> myproject
        --> package.json
        --> src
```

The `mylibaray` project has the name `@andrew/mylibrary` and it contains a function called `reallyGood`. I need to import and call that function from myproject. 

{% include ad-top-text.html %}

Here is the code for myproject.

```ts
// src/index.ts
import {reallyGood} from '@andrew/mylibrary';

function run() {
    const outcome = reallyGood();

    console.log(outcome);
}

run();
```

I am using `ts-node` to run it locally. The problem is that when I run it I get this error:

```
Error: Cannot find module '@anndrew/mylibrary'
```

The problem is that `ts-node` has no idea where to find a module called `@andrew/mylibrary`.

## Adding paths to tsconfig.json

In `myproject` I can open the `tsconfig.json` and manually provide the path. 

```json
{
    "compilerOptions": {
        "paths": {
            "@andrew/mylibrary": ["../mylibrary"]
        }
    }
}
```

This will tell the build process where to find the import. It’s not ideal if you want to push versions of your library to a repository, but for local development, it works fine. That allows me to build the code with `tsc` but it will still fail when run with `ts-node`. The problem is that `ts-node` does not respect the paths object by default. 

## Making ts-node use paths

To make `ts-node` use the paths object from the compiler, you need to add some additional configuration. First install the `tsconfig-paths` library in your project.

```
npm i -D tsconfig-paths
```

Then register it for `ts-node` in the `tsconfig.json` file.

```json
{
  "ts-node": {
    "require": ["tsconfig-paths/register"]
  },
  "compilerOptions": {
    // paths etc.
  }
}
```

Now `ts-node` will use the paths and everything should work.

{% include ad-bottom-text.html %}

## Summary

Building local libraries with `ts-node` is a great way to get code working quickly but some of the error messages are not very clear. This took me a while to look up and get working, so hopefully, it will help you too.
