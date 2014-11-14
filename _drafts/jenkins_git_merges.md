Merging with git branches with Jenkins

Jenkins offers a lot of great features beyond just testing your code. Today we will look at merging branches with Jenkins. This is a really useful feature because you can ensure your tests are updated before anything is committed to specific branches. In most projects you will have some branches that should always be stable, often called `master` or `deploy`. The problem with commiting code to these branches is that if there is a big it might take a while for Jenkins to finish all the tests and report the problem, by that time other developers might have branched and suddenly there is bug that ugently needs fixing.

A simple solution to this problem is to only allow Jenkins to handle this merge. Jenkins can merge the branches, do the tests and then push the changes back to the repository if the tests all pass. This way you know the `master` branch is always clean.

Set up

I assume you have Jenkins installed and the git plugin enabled. To add the merge you need to find the `Additional Behaviours` section under `Source Code Management` and open the `Add` drop down. Select `Merge before build` and an additional section will be added to the form. 