Running Jenkins for a Bitbucket Pull Request

As a user of both Jenkins and Bitbucket I have found myself wanting to run my tests when someone in my team raises a pull request. We use pull requests internally for code reviews and it would be helpful for Jenkins to give it a try before geting a developer to look at it.

Anyone who has contributed to open source will probably be used to Travis CI running when a pull request is raised on GitHub. It's a really useful practice so I would be nice to do the same thing for Bitbucket and Jenkins.

Setting up Jenkins

There is a really useful Jenkins plugin that we called the [Bitbucket Pull Request Plugin](https://github.com/jenkinsci/bitbucket-pullrequest-builder-plugin). This extremly useful plugin is lacking a bit of documentation so here I will try to show you how to set it .

The first thing to do is install it from the Jenkins plugins page. It is availble in the main plugins repo so it should be easy to find.

Set up your build

Create a new project and go to the configure page. The steps jump around the page a bit but they do work.

First go to the build triggers and pick the `Bitbucket Pull Requests Builder`. When you select the checkbox you will get the options for the configuration. Unfortunatly none of the options include a help section but they are fairly simple.

![Jenkins pull request builder](/images/jenkins/jenkins_pull_request_builder.png)

In the cron field I normally enter `* * * * *` so it will keep on checking.

The basic username and password fields are just your credentials. It would be nice these values could be set in the global configuration but that does not appear possible. I set up a Jenkins user on Bitbucket so I did not need to give my admin account credentials.

The repository owner and repository name are in the git url i.e. for `git@bitbucket.org:myname/myproject.git` your would enter `myname` and `myproject` respectivly.

The `CI Skip Phrases` allows you to not build if there are specific messages in the comment like 'updating readme'. I do not use it but you might find it useful.

The `Rebuild if destination branch changes?` option will rerun the tests if your destination branch is changed. This can be useful if you have pull requests open for some time but be careful, if you have 5 pull requests open and you merge 1 then the other 4 will be built, if your have a large build it will take a while to do them all.

Finally the `Approve if build success?` option allows Jenkins to press the approve button on the Bitbucket pull request. This is useful to quickly see a change but it doesn't do anything else.

The merge

In order to merge the branches we need to use some environment varaibles that are added by the pull request plugin. These are not all documented so it required some testing but this seems to work.

![Jenkins pull request builder](/images/jenkins/jenkins_pull_request_merge.png)

You need to enable `Merge before build` in the additional behavious menu. The branch to build needs to be `${sourceBranch}` and the branch to merge to is `${targetBranch}`. That will merge the pull request before running the tests.

Run the test

Finally you can run the tests as normal. If the build passes the approval will be added to Bitbucket and you should see some comments from Jenkins. 
