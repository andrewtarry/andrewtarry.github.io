---
layout: post
title: How to download an entire S3 bucket
description: If you have a lot of data in AWS S3 then downloading it all had be hard. Here are a selection of ways to do it quickly
date: 2024-02-19 01:10:00 +0000
categories: [AWS, S3]
tags: [AWS]
---

S3 is a great place to store your files when you’re using AWS. It gives us a safe and reliable location for files. It is one of the most commonly used AWS services, and its capacity is almost infinite. The challenge is that sometimes, we need to work with files locally.

There are a few options when it comes to getting files out of S3. The best option depends on how many files you have and how large they are.

## The AWS Console

If you only have a few files, you can download them from AWS directly. Go to the console, find the bucket you need and download the files you want.

![s3.png](/assets/img/aws-s3/s3.png)

This approach feels simplistic because it is. It’s a non-technical approach to downloading files that anyone can do without the need to think about code. The nice thing about this method is that a manager or apprentice could get the files they need, and there’s little risk of anything going wrong.

{% include ad-top-text.html %}

The downside is that if there are hundreds or thousands of files to deal with, this will not work. It will become tedious and unproductive.

## AWS s3 sync

A more technical approach will be to use AWS CLI. To do this, the user will need to be comfortable with the command line and have the CLI installed and configured with access keys.
For most developers, this should be a comfortable approach, and if you are using AWS regularly, then you probably have everything ready.

```bash
aws s3 sync s3://my-bucket ./my-local-folder
```

This command will copy the contents of a bucket named `my-bucket` to a local directory called `my-local-folder`. You could use an absolute path if the local directory is somewhere else. You can also use subfolders of the bucket if you want, like this: `s3://my-bucket/important/`.
This command is recursive by default, so you will get all the contents. The files will be downloaded sequentially, so a large bucket will take some time, but if you wait long enough, you will get everything.

There are also extra options like `--exclude` if you want to avoid downloading some file types.
The advantage of `s3 sync` is that you can automate the download of an entire bucket, and there are options to get files in a more fine-grained way. The tool is probably already installed on the developer’s devices. The only downside is that it can be slow for large buckets. In some cases it can take days or even weeks to get a large bucket.

## Cyberduck

If you want to use a graphic tool, then Cyberduck is a great choice. It’s a powerful FTP client, and it can use S3. It is a commercial product, and you are not going to get your files any faster, but it does provide an option for those who do not want to use the CLI.
You can download an entire bucket without needing to get the files individually. This means you can avoid giving the task to a developer, and there is no need for CLI tools. The limitation is that the file download will not be any faster than the CLI, so the only gain is who can do it.

## Do you need to download the s3 bucket?

Taking large amounts of data out of AWS is slow and can be expensive, so it is work asking if you really need to do it. If you can avoid it, then do.
One option is to do your processing on an EC2 instance. Instead of downloading all the files, just get what you need when you need it. By keeping the data inside AWS, you save costs, and the process can be more efficient.

It is also worth thinking about what you will use the data for. If you are analysing data, consider AWS Athena or EMR to process the data in the cloud with dedicated tools. That will save you from having to download files and give you powerful tools to use.

Finally, consider your process. If you have a large S3 bucket, what will you do with all that data? If you must download it for local processing, consider using the AWS SDK to get the files, process them, and keep the outputs. If you split the files in a smart way, you could even run lots of processing jobs on different machines to speed up the process. The advantage is that you do not need to wait for a slow sync that might be outdated by the time you finish.

## Conclusion

There are some great tools out there to download the contents of an S3 bucket, but be careful. You can download an entire bucket, but consider your needs. If it is a small bucket, then go ahead and grab all the contents. For larger buckets, it is going to be a slow process.

The best tool will probably be the AWS CLI, but try to find a way to avoid it in the first place. If you can do your analysis in the cloud or make the download of individual files part of a process, it will be faster and easier.