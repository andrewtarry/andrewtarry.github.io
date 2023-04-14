---
layout: post
title: How to use Handbrake to Transcode Films for Plex
description: HandBrake is a great free tool that allows you to transcode movies. Here I will explain how I transcode films using only the command line
date: 2023-03-21 17:10:00 +0000
categories: [MakeMKV, Plex, Handbrake]
tags: [MakeMKV, Plex, Handbrake]
og_image: /assets/img/handbrake/handbrake-logo.png
image: /assets/img/handbrake/handbrake-logo.png
---

In my previous article, I discussed how I [rip content from DVDs and Blu-ray for my home media server](https://andrewtarry.com/posts/rip-films-for-plex/). I use MakeMKV for that and the output is a rather large `.mkv` file. In this article, I will cover how to convert this into a `.mp4` file and add it to Plex.

## Why convert mkv to mp4?

There are two main reasons to convert the files, size and compatibility. 

The size benefit is fairly simple. If you rip a Blu-ray, you will get a `.mkv` file that is around 40GB in size. With files that large, you will quickly run out of space. After converting to `.mp4`, even with a high-quality level, you will get a file of around 10-15GB. That’s still big, but it’s better than before.

If disk space is a problem for you then you can reduce the quality during the conversion process. 

{% include ad-top-text.html %}

The other reason to convert is compatibility. Plex will often transcode a `.mkv` file while playing it. Technically Plex does support `mkv` but it’s complicated. Some `mkv` files will need transcoding, and some will not. To keep things, simple lets assume your `mkv` file will need transcoding.

Plex has the option of live-transcoding. This is when the file is transcoded while it’s playing but that has problems. The main one is that transcoding is a complex process. When you transcode a large file like a Blu-ray movie, you will need either a powerful computer or a lot of time. If you server is not very powerful or you are using a NAS, it might not be possible to transcode. The best thing to do is to transcode in advance.

## Transcoding on a server

I use [HandBrake](https://handbrake.fr/) to transcode movies. HandBrake is a free tool to transcode media files. Most of the documentation will discuss using its Windows or Mac applications as desktop tools. That side is all fairly simple, but I needed to use it on a server with a command line.

Using the HandBrake CLI it is possible to transcode files in a headless way and even write a script to process several of them at once.

## Installing HandBrake CLI

I am using Ubuntu so installing it was fairly easy.

```
$ sudo apt update
$ sudo apt install handbrake-cli
```

This installed the command `HandBrakeCLI`. Be careful with the case of this command. Some of the documentation has it all in lowercase.

## Converting a film with HandBrake CLI

First, you need to select a preset to use. If you know what you are doing, there are a lot of options, but I suggest starting with preset. This will list the current presets.

```
$ HandBrakeCLI --preset-list
```

There are a lot of presets, but the `General` list should contain something suitable. I use ` Super HQ 1080p30 Surround` and have found it to be good. 

Once your preset is selected you can convert a film. There are a lot of CLI options, but this is what I use:

```sh
HandBrakeCLI --preset 'Super HQ 1080p30 Surround' --format av_mp4 --align-av --markers -i "${directory}/${source}" -o "${directory}/${outputFileName}"
```

You can add your own source name and output name. Remember the output name should end in `.mp4`.

{% include ad-bottom-text.html %}

This command will take some time. For my server, a Blu-ray will take 6-8 hours, my server is old, and I want to use a high-quality preset. I normally put a few of these commands in a bash script and leave it to run.

## Adding to Plex

Once the movie has been transcoded, it can be added to Plex. The Plex directory structure is fairly simple.

```
Plex root/
  Movies/
    Movie Name (Year) {imdb}
```

For example, I might have a film called `Movies/ Rouge One (2016) {imdb-tt3748528}/rouge_one.mp4`.

Plex will pick that up and add all the metadata. The `imdb` is optional but I like to add it so there is no confusion.

That is how I transcode movies.
