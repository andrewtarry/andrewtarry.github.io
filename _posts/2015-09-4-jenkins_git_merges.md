---
layout: post
title: Merging with git branches with Jenkins
description: Jenkins offers a number of plugins to help teams keep their stable branches stable. Here's how to set it up
---

Jenkins offers a lot of great features beyond just testing your code. Today we will look at merging branches with Jenkins. This is a really useful feature because you can ensure your tests are updated before anything is committed to specific branches. In most projects you will have some branches that should always be stable, often called `master` or `deploy`. The problem with committing code to these branches is that if there is a bug it might take a while for Jenkins to finish all the tests and report the problem, by that time other developers might have branched and suddenly there is bug that urgently needs fixing.

A simple solution to this problem is to only allow Jenkins to handle this merge. Jenkins can merge the branches, do the tests and then push the changes back to the repository if the tests all pass. This way you know the `master` branch is always clean.

##Set up

I assume you have Jenkins installed and the git plugin enabled. To add the merge you need to find the `Additional Behaviours` section under `Source Code Management` and open the `Add` drop down. Select `Merge before build` and an additional section will be added to the form.

![Jenkins source control during a merge](/images/jenkins/jenkins_merge.png)

Here I am merging the `develop` branch into `master` before I run my tests. If there are any merge conflicts the test will fail, which is likely to be what you want because you should fix the conflict before merging to a stable branch.

##Running the tests

Once the merge is successful Jenkins will continue as normal. Assuming your tests pass you will see the job complete and you can then be confident in merging your code.

##Pushing the merge

If you would like to push result of the merge back to your repository you will need the Git Publisher post build action that comes with the [Git Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin). I would suggesting checking the boxes for `Push Only If Build Succeeds` and `Merge Results`. Some people like to add tags or notes but that's up to you.

![Jenkins push merge result](/images/jenkins/jenkins_push.png)

In order for Jenkins to push the result back to your repository you will need to make sure you have given write access. Some git providers, including GitHub and Bitbucket, offer deployment keys that allow you to give servers read only access. That works great for a deployment server but if you want to push a merge result back you will need to private Jenkins with a full user account.
