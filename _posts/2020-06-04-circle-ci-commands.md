---
layout: post
title: Circle CI Commands
description: Commands allow resable code within a Circle CI pipeline that makes the pipeline easier to manage and configurable for the engineers
date: 2020-06-04 14:10:00 +0000
categories: [DevOps, Circle CI]
tags: [circle ci, devops, pipeline]
---

Cricle CI Commands

Cricle CI now as the option to create reusable steps in your pipeline that act almost as functions. Using commands it is now possible to create standard parts of the pipeline without needing to use external tools.

Commands are a great feature that seem to be a bit buried in the rest of the [documentation](https://circleci.com/docs/2.0/configuration-reference/#commands-requires-version-21). Here I will try to talk about them in some more detail.

## The problem that this solves

Commands are particularly useful when used which a monorepo. A [monorepo]((https://www.perforce.com/blog/vcs/what-monorepo)) is a practice for development teams to keep all their code together in a single git repo. When designing a CI pipeline for a monorepo we often need to deal with each directory separately. 

Imagine a Circle CI workflow like this:

```yaml
version: 2.1
orbs:
  node: circleci/node@2.0.3


workflows:
  build:
    jobs:
		- project1
		- project2

jobs:

  project1:
    executor:
      name: node/default
      tag: '12.16'
    steps:
      - checkout
      - node/install-yarn
      - restore_cache:
          key: dependency-cache-{{ checksum "project1/yarn.lock" }}
      - run:
          name: Yarn install
          command: yarn
          working_directory: project1
      - save_cache:
          key: dependency-cache-{{ checksum "project1/yarn.lock" }}
          paths:
            - project1/node_modules
	- run:
          name: Yarn test
          command: yarn test
          working_directory: project1
          environment:
            CI: true


  project2:
    executor:
      name: node/default
      tag: '12.16'
    steps:
      - checkout
      - node/install-yarn
      - restore_cache:
          key: dependency-cache-{{ checksum "project2/yarn.lock" }}
      - run:
          name: Yarn install
          command: yarn
          working_directory: project1
      - save_cache:
          key: dependency-cache-{{ checksum "project2/yarn.lock" }}
          paths:
            - project2/node_modules
	- run:
          name: Yarn test
          command: yarn test
          working_directory: project1
          environment:
            CI: true

```

In this example we have 2 javascript projects in the repo, for both of them we need to checkout the code, install yarn, fetch the dependencies and then run the test. The details of the pipeline do not really matter, the important part is that we have a pipeline that has 2 builds with almost the same steps. 

As more projects get added our pipeline will grow with repeating code, which any engineer will feel is wrong. There are 2 main ways to solve this problem, build scripts and commands.

## Build scripts

The first option to remove the duplication is to introduce build scripts. These could be done with almost any language but common choices would be bash or make. We could create a javascript tool but the principle is the same, we could combine the build steps into a single step to remove some of the duplication in the pipeline.

Our new pipeline might be more like this:

```yaml
version: 2.1
orbs:
  node: circleci/node@2.0.3


workflows:
  build:
    jobs:
		- project1
		- project2

jobs:

  project1:
    executor:
      name: node/default
      tag: '12.16'
    steps:
      - checkout
      - node/install-yarn
      - restore_cache:
          key: dependency-cache-{{ checksum "project1/yarn.lock" }}
      - run:
          name: Test
          command: ./test.sh project1
      - save_cache:
          key: dependency-cache-{{ checksum "project1/yarn.lock" }}
          paths:
            - project1/node_modules


  project2:
    executor:
      name: node/default
      tag: '12.16'
    steps:
      - checkout
      - node/install-yarn
      - restore_cache:
          key: dependency-cache-{{ checksum "project2/yarn.lock" }}
      - run:
          name: Test
          command: ./test.sh project2
      - save_cache:
          key: dependency-cache-{{ checksum "project2/yarn.lock" }}
          paths:
            - project2/node_modules
```

Using a build script we have been able to remove a few lines but there is a lot that we cannot reduce. The problem is that steps like `checkout`, `restore_cache` or `save_cache` are all part of Circle CI that cannot be easily used in a custom script. This problem is not unique to Circle CI, every CI tool has special commands that form part of their DSL and we cannot easily use in a custom script.

The other problem that this solution presents is the location of an error. If the dependency installation or the tests or a syntax problem in the `test.sh` occur the error will appear in the same place. The onus is on the developers to ensure the error reporting is clear enough that we can see the real cause of the problem in the logs.

Build scripts offer some improvements, particularly for complex builds, but they come with a lot of limitations.

## Circle CI Commands

Commands offers the best of both worlds. We can create a command to run our test, complete with custom commands.

```yaml
version: 2.1
orbs:
  node: circleci/node@2.0.3


workflows:
  build:
    jobs:
		- project1
		- project2

commands:
	yarn_test:
		description: Configure Yarn
	    parameters:
	      directory:
	        type: string
	    steps:
		  - checkout
	      - node/install-yarn
	      - restore_cache:
	          key: dependency-cache-{{ checksum "<< parameters.directory >>/yarn.lock" }}
	      - run:
	          name: Yarn install
	          command: yarn
	          working_directory: << parameters.directory >>
	      - save_cache:
	          key: dependency-cache-{{ checksum "<< parameters.directory >>/yarn.lock" }}
	          paths:
	            - << parameters.directory >>/node_modules
		- run:
	          name: Yarn test
	          command: yarn test
	          working_directory: << parameters.directory >>
	          environment:
	            CI: true


jobs:

  project1:
    executor:
      name: node/default
      tag: '12.16'
    steps:
		- yarn_test:
			directory: project1

  project2:
    executor:
      name: node/default
      tag: '12.16'
    steps:
		- yarn_test:
			directory: project2

```

Now we have all the steps to checkout the code, configure the cache and dependencies as well as test in a single command. Command parameters make it act more like a function with input that make it reusable throughout the pipeline. In addition there is the option for commands to use Circle CI bespoke keys and even other commands. 

As the pipeline grows the command can be reused again and again to keep the total size of the code down. With the opportunely to compose commands by breaking the steps down and having one command use another we get a flexible and powerful CI syntax.

When the pipeline is run, each step in the command is executed separately so it becomes really easy to find problems.

## Conclusion

Commands in Circle CI is, in my opinion, on of the best features in the platform. They allow reusable code as part of the pipeline and enable a large, complex pipeline to remain manageable as it grows. Commands are one of the reasons why Circle CI remains my first choice for CI services.

Now if they would just allow us to split a pipeline over more than one file…