---
layout: post
title: How I rip film for Plex
description: Plex and other media servers allow you store your films and have a personal media libaray. The challenge is getting the films into the library to start with
date: 2023-02-22 01:10:00 +0000
categories: [MakeMKV, Docker]
tags: [MakeMKV, Plex, Docker ]
og_image: /assets/img/makemkv/makemkv.png
---

I have a large media library of DVD’s and Blu-Ray films that I have been adding to my Plex server. We have several TV’s around the house and it’s just easier than having to hunt around the house for the film I want to watch. 

I use an external Blu-Ray player that’s plugged into my homelab server. I could do all this on my normal laptop, but an average Blu-Ray film can take up 40GB on the disk and I just don’t have the space for that.

{% include ad-top-text.html %}

## The player

<div style="float: right"><iframe sandbox="allow-popups allow-scripts allow-modals allow-forms allow-same-origin" style="width:120px;height:240px;" marginwidth="0" marginheight="0" scrolling="no" frameborder="0" src="//ws-eu.amazon-adsystem.com/widgets/q?ServiceVersion=20070822&OneJS=1&Operation=GetAdHtml&MarketPlace=GB&source=ss&ref=as_ss_li_til&ad_type=product_link&tracking_id=perrio09-21&marketplace=amazon&region=GB&placement=B07MTP9VKX&asins=B07MTP9VKX&linkId=c60b32e8d384c5df8d30b69a0caec4dc&show_border=true&link_opens_in_new_window=true"></iframe></div>

I use a [Verbatim External Slimline Drive](https://amzn.to/3xJ0wst), you could use something else but this works really well for me. 

I had considered an internal drive like the [LG MDisc](https://amzn.to/3Ev1oVD) that my colleage uses and adding it to my server. That would work really well but I wanted the option to take the drive with me if I ever needed to.

My drive is plugged in a USB port, so it’s fairly easy to use.

## Using MakeMKV

[MakeMKV](https://www.makemkv.com/) is a fantastic tool to extract the contents of a disk to your hard drive. It has an easy-to-use UI so anyone can do it. The only problem is that my server only has a command line interface. 

To get around this problem I am using the [MakeMKV docker image](https://hub.docker.com/r/jlesage/makemkv). I need to pass the docker image a number of options so I wrote a script to handle it.

```bash
#!/usr/bin/env bash
set -e

MOVIES_TMP=/mnt/media1/share/moviestmp
MAKEMKV_VERSION=v1.22.2
DEVSR=$(lsscsi -g | grep BD | awk '{print $7}')
DEVSG=$(lsscsi -g | grep BD | awk '{print $8}')

docker run -p 5800:5800 -v $MOVIES_TMP:/output:rw -v /docker/appdata/makemkv:/config:rw -v $HOME:/storage:ro --device $DEVSG --device $DEVSR jlesage/makemkv:$MAKEMKV_VERSION
```

Using the `lesscsi -g` command, I can see the mount points for Blu-Ray player. There are two of them and you need both to make it work. I also mount several directories so that the files are written to disk.

{% include ad-bottom-text.html %}

## Copying a disk

Now I run my script and I can access MakeMKV in a browser. In my case, it is `http://< my server IP address>:5800`. I put in a disk and it will list everything I can export. There are sometimes a lot of files so I look for the largest one and copy that. Most of the rest are extras that I don’t really need.

![Makemkv](/assets/img/makemkv/makemkv.png)

The copying process takes a while but I can leave it while it runs and because it’s not using my main computer. 

Once it finishes you will have a new `.mkv` file of your film. You could add this plex but `.mkv` is a bit of an odd format. It’s very big, and you will normally need to transcode it. Plex and other media servers can often perform live transcoding, but they will place a lot of strain on the server. If you only have a small server or a NAS that’s not ideal. 

In the next article, I will share my transcoding scripts.
