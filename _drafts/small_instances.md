You don't want a bigger instance

I am a big fan of Amazon Web Services and host a lot of projects there. One thing I keep on hearing from people when they first start using AWS is that they need to switch to a bigger instance. Often this happens when their application is getting busier or they have introduced some new functionality that is consuming resources. My response is always the same - if the only answer is a bigger instance then you're probably doing it wrong!

Structuring a web application

Web based applications likely to be the common usecase people are facing and they are a prime case of bigger not being better. All web applications are rougthly the same from a very high level:

1. A request comes it
2. The application does things e.g. accessing a database, call an api etc
3. The application generates a response, which could be an html page, json or anything else
4. The response is sent

All applications are different but most web applications will follow this basic pattern. If that is what you are doing then why would you ever need anything larger than medium sized instance?

The great benifit of hosting an application on AWS is that your application can scale. Amazon offer some great tools to help with this. My favorite approch is Elastic Beanstalk that allows you to host an application, written in a variety of languages or in a Docker container, with auto scaling built in. Most web applications should be able to fit into the Elastic Beanstalk pattern and increase the number of nodes you need when the traffic increases. For more complex applications there is option of AWS Ops Works to achive the same effect. In either case there should not be a need to go above a medium instance. 

AWS based applications should be able to scale horizontailly, meaning that if your application needs more power the solution is more servers rather than bigger servers. The advantage is that you have far greater redundency 