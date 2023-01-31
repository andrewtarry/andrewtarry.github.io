---
layout: post
title: Putting React in Barrels
description: React projects can grow in complexity so the Barrel appraoch can help to keep the code clean and simple
date: 2022-08-10 01:10:00 +0000
categories: [React, UI]
tags: [React, React Barrel]
---

![Barrels](/assets/img/react-barrels/barrels.jpg)

When working on a large React project, it can quickly become difficult to manage the code. You will probably have a components folder that contains all the code but how do you find what you need?

To make life easier your can structure your code using folders. Then Barrels is an approach to make it easier to import your code throughout your project.

{% include ad-top-text.html %}

## Problem Code

Image you have a code case base that looks something like this:

```
-src
---footer.css
---footer.tsx
---footer.test.tsx
---input.css
---input.tsx
---input.test.tsx
---navbar.css
---navbar.tsx
---navbar.test.tsx
-page
---index.tsx
---about.tsx
```

In this structure all the components are being added to the `src` folder. Each component has a test file and some css. The problem is that your imports are already getting complex. At the top of the pages you will probably see something like this:

```typescript
import {Navbar} from '../src/navbar';
import {Footer} from '../src/footer';
import {Input} from '../src/input';
```

As you add code to your project this is going to get more and more complex. Finding the code you need will become so tricky that time is lost searching the code base. As more engineers join your team they will spend longer and longer learning the codebase. And of course, there are still opportunities to make it worse. Do you want to add `storybook`? Maybe someone wants to start adding `x.props.ts` files next to each component to store interfaces. That `src` folder is getting big

## Step 1: Add folders

The first step is to clean up your folder structure. This will allow you to keep all the files related to a component together. While we're at it, lets add a `components` folder since we might need to add code that is not a component in the future.


```
-src/
--components/
---footer/
-----footer.css
-----footer.tsx
-----footer.test.tsx
-----footer.stories.ts
---input/
-----input.css
-----input.tsx
-----input.props.ts
-----input.test.tsx
---navbar/
-----navbar.css
-----navbar.tsx
-----navbar.test.tsx
-page/
---index.tsx
---about.tsx
```

This is better and we can add stories or props files if we need to. Everything is cleaner but how does it impact the imports?


```typescript
import {Navbar} from '../src/components/navbar/navbar';
import {Footer} from '../src/components/footer/footer';
import {Input} from '../src/components/input/input';
```

That's actually worse since we now have more of our folder structure in every file.

## Step 2: Add barrels

A barrel is just a file that only exports files from multiple other files. It contains all our code so that imports become easier. A barrel is almost always called `index` because that is the default file that will be loaded. 

```
-src/
--components/
---footer/
-----footer.css
-----footer.tsx
-----footer.test.tsx
-----footer.stories.ts
-----index.ts
---input/
-----index.ts
-----input.css
-----input.tsx
-----input.props.ts
-----input.test.tsx
---navbar/
-----index.ts
-----navbar.css
-----navbar.tsx
-----navbar.test.tsx
---index.ts
-page/
---index.tsx
---about.tsx
```

So whats inside each of the `index.ts` files? In our components they might only have one line:

```typescript
// src/components/footer/index.ts
export * from 'footer';
```

This allows us to decouple the exports from the file names. You could only export one component or more if needed.

### What not put the component in an index.tsx?

Yes you could do that but don't. The problem is as you open more and more files in your editor you will find they are all called `index.tsx` it's going to get confusing. Naming them to match the component will make file easier.

{% include ad-bottom-text.html %}

### Whats in the `components/index.ts`?

This is the key to the barrel approach.

```typescript
// src/components/index.ts
export * from 'footer';
export * from 'navbar';
export * from 'input';
```

Here the components can all be exported in a single file. The imports in the page can now be done like this:

```typescript
import {Navbar, Footer, Input} from '../src/components';
```

Now we have a one-line import and your components are not coupled to the file structure. If you need to move some of these components around in the future then that's no problem, as long as you also update the barrel. The rest of the code will not know about your file system change.

## What are the downsides?

Some people do not like barrels on because it adds a more complex structure and lots of files that don't really add anything. While this is true, it's not something I agree with. Yes it will add files but I think it reduces the overall complexity. As with anything in React there will always be options but for me, this approach makes my projects clearer and easier to understand.


























