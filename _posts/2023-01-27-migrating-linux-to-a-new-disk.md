---
layout: post
title: Migrating Linux to a new Disk
description: If you need to move your operating system to a new disk without reinstalling everything, here are the steps to follow
date: 2023-01-27 01:10:00 +0000
categories: [Linux, Ubuntu, Disks, BIOS]
tags: [Linux]
---

I have a homelab server. It’s an old workstation that now runs all sorts of services for me, from Plex to Kubernetes and Jenkins. It’s extremely useful since it allows me to test ideas without going to the cloud. It runs Ubuntu server edition so everything is done over SSH.

The problem is that it originally only had an old hard disk inside. It wasn’t very big, and I’m out of space so I needed an upgrade. I have a new SSD and 2 larger HDDs that will run as a RAID (more on that in the future). I need to transfer the OS and all the files to the new SSD without reinstalling Ubuntu. 

Technically, I could reinstall everything since it’s all managed with Ansible, but that seemed like a bad solution.

{% include ad-top-text.html %}

I am not a Linux Admin, so my approach might not be the best. I pieced this together from blogs, `man` pages, plus some trial and error. It’s not perfect, but it worked for me.

## Drive Partitions

First, I installed the new SSD and added the SATA port to the BIOS. When the system started, I checked the disks.

```sh
$ lsblk
sda                         8:0    0 111.8G  0 disk
sdb                         8:16   0 465.8G  0 disk
├─sdb1                      8:17   0     1M  0 part
├─sdb2                      8:18   0     2G  0 part /boot
└─sdb3                      8:19   0 463.8G  0 part
  ├─ubuntu--vg-ubuntu--lv 253:0    0   100G  0 lvm  /
  └─ubuntu--vg-media      253:1    0 363.8G  0 lvm  /mnt/media0
```

For some reason, my old HDD was in slot b, and so my new SSD is going in slot a. 

A lot of blogs will tell you to use something like `gparted` to set up the partitions but since I’m doing everything over SSH I am going to use `fdisk`. First I checked the drives.

```
$ fdisk -l
Disk /dev/sdb: 465.76 GiB, 500107862016 bytes, 976773168 sectors
Disk model: ST500DM002-1SB10
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 55A4C222-9CCB-4298-B2A0-A0ED180F2DAB

Device       Start       End   Sectors   Size Type
/dev/sdb1     2048      4095      2048     1M BIOS boot
/dev/sdb2     4096   4198399   4194304     2G Linux filesystem
/dev/sdb3  4198400 976771071 972572672 463.8G Linux filesystem


Disk /dev/sda: 111.8 GiB, 120040980480 bytes, 234455040 sectors
Disk model: WDC WDS120G2G0A-
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

```

Next using `fdisk` I reproduced the 3 partitions. I kept partitions 1 and 2 the same size as the old disk and used the rest of the space for partition 3.

```
$ fdisk /dev/sda

Welcome to fdisk (util-linux 2.37.2).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0xd94e439a.

Command (m for help): m

Help:

  DOS (MBR)
   a   toggle a bootable flag
   b   edit nested BSD disklabel
   c   toggle the dos compatibility flag

  Generic
   d   delete a partition
   F   list free unpartitioned space
   l   list known partition types
   n   add a new partition
   p   print the partition table
   t   change a partition type
   v   verify the partition table
   i   print information about a partition

  Misc
   m   print this menu
   u   change display/entry units
   x   extra functionality (experts only)

  Script
   I   load disk layout from sfdisk script file
   O   dump disk layout to sfdisk script file

  Save & Exit
   w   write table to disk and exit
   q   quit without saving changes

  Create a new label
   g   create a new empty GPT partition table
   G   create a new empty SGI (IRIX) partition table
   o   create a new empty DOS partition table
   s   create a new empty Sun partition table 
```

Once I was done the disks looked like this:

```
$ fdisk -l
Disk /dev/sdb: 465.76 GiB, 500107862016 bytes, 976773168 sectors
Disk model: ST500DM002-1SB10
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 55A4C222-9CCB-4298-B2A0-A0ED180F2DAB

Device       Start       End   Sectors   Size Type
/dev/sdb1     2048      4095      2048     1M BIOS boot
/dev/sdb2     4096   4198399   4194304     2G Linux filesystem
/dev/sdb3  4198400 976771071 972572672 463.8G Linux filesystem


Disk /dev/sda: 111.8 GiB, 120040980480 bytes, 234455040 sectors
Disk model: WDC WDS120G2G0A-
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xd94e439a

Device     Boot   Start       End   Sectors   Size Id Type
/dev/sda1  *       2048      4095      2048     1M 83 Linux
/dev/sda2          4096   4198399   4194304     2G 83 Linux
/dev/sda3       4198400 234455039 230256640 109.8G 83 Linux
```

## Boot Partition

My system uses a traditional BIOS-based boot I did not have EFI to worry about. I mounted partition 2 to `/boot` and installed `grub`.

```sh
$ umount /boot
$ mount /dev/sda2 /boot
$ grub-install
$ update-grub
```

Next I added this line to my `/etc/fstab` file so that the new boot directory would mount on startup.

```
/dev/sda2 /boot ext4 defaults 0 1
```

I also commented out the old `/boot` volume. I restarted the server and changed the BIOS settings to boot from the SSD.

## Moving data

Now my server was booting from the SSD, but all the data was still in the wrong place. To fix this, I had to move the Ubuntu Logical Volume Group (LVG) to the new disk. My LVG was actually larger than the entire SSD because I was running a Plex server. I had many movies on the disk that were too big for the SSD.

First, I plugged in my new HDDs and set up the RAID (I’ll cover that in another blog). I copied all the files from the LVG onto the RAID and updated Plex to use the new location. Then I removed by `media` Logical Volume from the group.

```
$ unmount /mnt/media0
$ lvremove /dev/ubuntu-vg/media
```

Also make sure you move the volume from your `/etc/fstab` file or the system will error when it tries to start.

Now the data in the LVG was nice and small. I started by adding the new SSD to the LVG.

```
$ pvcreate /dev/sda3
$ vgextend ubuntu-vg /dev/sda3
```

This allows the LVG to use both drives. Next I moved the data off of the old disk.

```
$ pvmove /dev/sdb3
```

This took some time but when it was done I removed the old disk from the LVG.

```
$ vgreduce ubuntu-vg /dev/sdb3
```

{% include ad-bottom-text.html %}

Now all the data is on the new SSD or the RAID. My disks look like this

```
$ lsblk
sda                         8:0    0 111.8G  0 disk
├─sda1                      8:1    0     1M  0 part
├─sda2                      8:2    0     2G  0 part  /boot
└─sda3                      8:3    0 109.8G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0   100G  0 lvm   /
sdb                         8:16   0 465.8G  0 disk
├─sdb1                      8:17   0     1M  0 part
├─sdb2                      8:18   0     2G  0 part
└─sdb3                      8:19   0 463.8G  0 part
sdc                         8:32   0   3.6T  0 disk
└─md0                       9:0    0   3.6T  0 raid1 /mnt/media1
sdd                         8:48   0   3.6T  0 disk
└─md0                       9:0    0   3.6T  0 raid1 /mnt/media1
```

## Removing the disk

The final step was to shut down the server and remove the old HDD. I had to update the BIOS one more time to turn off the SATA port, and then I could restart into Ubuntu.

Now I have an SSD for all the working files and a RAID for my media.

## Summary

Working with hardware is unusual for most developers today but getting an old computer and playing around like this is a massive learning opportunity. Today with the cloud, we rarely have to do things like this, but it’s surprisingly good fun to learn about. I probably could have done it better so let me know what I’ve missed.
