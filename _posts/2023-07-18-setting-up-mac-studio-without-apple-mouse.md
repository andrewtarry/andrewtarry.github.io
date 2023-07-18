---
layout: post
title: Setting up a Mac Studio without an Apple Keyboard and Mouse
description: When I recently purchased my new Mac Studio I had a problem, I do not own an Apple Magic Keyboard and Mouse. So how can you set it up?
date: 2023-07-18 01:10:00 +0000
categories: [Apple]
tags: [apple]
---

I recently received my new Mac Studio. It was an exciting day and I couldn’t wait to get it up and running. There was, however, a problem, how do you set it up?

I have an external (non-apple) keyboard and mouse. If you buy a laptop, you can complete the set-up using the trackpad and internal keyboard until you fully get in and can connect everything. What do you do with a Mac Studio?

![Mac Studio](/assets/img/apple/mac-studio.jpeg)

## Keyboard and Mouse

The only keyboard and mouse that will automatically be detected are the Apple Magic Keyboard and Mouse. Unfortunately, I don’t know anyone who uses either of those. Most engineers I know use third-party devices.

Personally, I use a NuPhy mechanical keyboard and a MX Master 3 mouse. The mouse is connected over Bluetooth, but my keyboard is wired using USB. That’s a bit unusual since there are Bluetooth options, but I like a good old wire.

There is no way to connect a third-party Bluetooth device during the set-up. This restriction to use Apple devices is a frustratingly Apple thing to do, they should allow a way to connect devices at the start but they don’t.

## How did I set up my Mac

I was able to connect the keyboard using USB, and it worked immediately. I had to do everything using the keyboard. I could use `TAB` to move around and `Space` to click on buttons. 

![Mac Studio Setup](/assets/img/apple/apple-setup.png)

I found the system would freeze on some screens, so I skipped the Apple ID and Wifi to get started. Once I could get through all the screens, it loaded into MacOS.

## Connecting the mouse

The next challenge was to connect the mouse. It should be easy but no.

You can enter System Setting by using `⌘ + Space` to open Spotlight and typing in System Settings. Then you use `TAB` to get to Search and look for Bluetooth. The problem is that you cannot use `TAB` to enter the right of the System Settings. 

{% include ad-bottom-text.html %}

I fixed this with a settings change. Use Spotlight to open the Terminal and enter this command.

```sh
$ defaults write NSGlobalDomain AppleKeyboardUIMode -int 2
```

This will allow you to tab around in the System Settings. You will need to restart your Mac first. To do that, use

```sh
$ shutdown -n now
```

Once your Mac restarts, you can open System Settings with the Spotlight and open the Bluetooth menu. Put your mouse in pairing mode and it should appear. Then you can `TAB` to the connect button and use Space to select it.

## Summary

This process is harder than it should be, but it can be done. Apple should make it easier to connect a Bluetooth device at the start of the set-up process but that’s the way it is.
Now that it’s working, I love my new Mac Studio. Pairing it with the NuPhy keyboard and MX Master mouse is perfect and I’m very happy.
