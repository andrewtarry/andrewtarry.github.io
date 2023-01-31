---
layout: post
title: RAID on Ubuntu
description: Setting up a RAID on Linux allows redundant storage on your server to manage your files safely
date: 2023-01-27 01:10:00 +0000
categories: [Linux, Ubuntu, Disks, RAID]
tags: [Linux, RAID]
---

In a [recent post]( https://andrewtarry.com/posts/migrating-linux-to-a-new-disk/) I mentioned my homelab and how I’ve been changing disks. One of the things I did was to set up some new disks in a RAID.

## Motivation

My homelab does a wide range of things. It is a media server for the kids to watch films, it has a Kubernetes cluster to test projects with, it is a backup of my data. All these things make heavy use of the disk and write important data. 

In my original homelab setup I had a 500Gb HDD that contained the operating system and all my data. I have [migrated the operating system](https://andrewtarry.com/posts/migrating-linux-to-a-new-disk) to a new SSD so I now need to plan for the rest of my data. At the time of the migration, there was around 400Gb of data, and I knew I had a few Terrabytes to come. I also wanted to protect the data, disks fail, and if I lost everything, it would take a long time to recover.

{% include ad-top-text.html %}

I decided to upgrade my storage with some new Hard Drives that I would configure in RAID 1. The reason for RAID 1 is that it gives me a redundant copy of the data, and it will improve the read time. I would have liked to go for something like RAID 5 so I could keep expanding as needed but the case would only fit 2 HDDs. I could have added a separate NAS, but that would have pushed the cost up too much, I probably will get a NAS eventually but for now I will add 2 disks.

## Set Up 

I have two new 4TB HDD’s that I purchased online. After connecting them to the power and SATA ports I enabled the additional ports in the BIOS and booted the system. First I checked they were connected.

```
$ lsblk
sda                         8:0    0 111.8G  0 disk
├─sda1                      8:1    0     1M  0 part
├─sda2                      8:2    0     2G  0 part /boot
└─sda3                      8:3    0 109.8G  0 part /
sdc                         8:32   0   3.6T  0 disk
sdd                         8:48   0   3.6T  0 disk
```

In my case the new drives are `sdc` and `sdd`. To create the RAID I used `mdadm`

```
$ sudo mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sdc /dev/sdd
```

This immediately created the RAID but the disks were not yet synced. I was able to check the status using like this

```
$ cat /proc/mdstat
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10]
md0 : active raid1 sdd[1] sdc[0]
      3906886464 blocks super 1.2 [2/2] [UU]
      [>....................]  resync =  0.0% (1623680/3906886464) finish=400.8min speed=162368K/sec
      bitmap: 30/30 pages [120KB], 65536KB chunk

unused devices: <none>
```

There was something very satisfying about watching the progress increase, even if it took a whole day. While that was going on I proceeded with the rest of the set up.

Next I configured the filesystem, I was using Linux so I used `ext4`. If you are using Linux and don’t know which filesystem to use `ext4` is a safe bet.

```
$ sudo mkfs.ext4 -F /dev/md0
```

Then I created my mount point and mounted the drive.

```
$ sudo mkdir -p /mnt/media1
$ sudo mount /dev/md0 /mnt/media1
```

Now I had a fully working RAID. I just needed to ensure it was available after a reboot. I used this command to save the current configuration: 

```
$ sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
```

Next, I updated the `initramfs` so that the RAID would start early in the boot process, I don’t think this is strictly necessary but it can’t hurt.

```
$ sudo update-initramfs -u 
```

{% include ad-bottom-text.html %}

Finally I added this line to my `/etc/fstab` file:

```
/dev/md0 /mnt/media1 ext4 defaults,nofail,discard 0 0
```

This will ensure the RAID is mounted at start-up.

## Moving data

The last thing to do was move the data. 

```
$ rysnc -r -P /mnt/media0 /mnt/media1
```

I could have just done `cp` but I wanted to see the progress. Once that was done, I just had to update a few paths in my Ansible playbook and everything worked.

## Summary

Using a RAID is giving me enough space and a redundant copy of the data. I will upgrade to full-on NAS eventually. I have been recently working with a [Synology NAS]( https://amzn.to/3JssRu2) that was excellent. I will upgrade to a NAS eventually, but this is working well as a quick and inexpensive solution.
