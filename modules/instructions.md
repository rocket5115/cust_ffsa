Place any modules you want to run constantly and that use the framework in any way.
Any *.lua will be treated as client-side script, only *-sv.lua will be treated as server-side script.
Client-Side files are executed from SERVER only! Do NOT include them in fxmanifest!
These files only can access self object after the client side has fully loaded!

Exception: Files with "!" at the start of the name, will be treated as server files. They have access to create and override functions and variables within Module self object
