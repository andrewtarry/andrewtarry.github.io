Why the logger should be your best friend

All the major PHP frameworks come with a logger straight out the box and there's a reason for that. Logging is a vital tool and one that can be overlooked if we're not careful. I have seen a number of applications over the years where the developers have done a good job in building the app but the debugging was a real pain because there was no logging.

Why log?

The logger is there to let you record what the application is doing as the user is progressing through it. If an error occours you need to know why and if you have added logging you can follow the events that resulted in that error. If you are using a framework like Symfony there will be a lot of logging going on that as part of the framework. This will help you debug errors in the database or configuration. You should still be adding you own logging so you can follow the business logic. 

All loggers offer different levels so you can decide how much logging to do. Normally production servers will only log errors but you can log a lot more in your testing and development environments.