Place any modules you want to run constantly and that use the framework in any way.
Any *.lua will be treated as client-side script, only *-sv.lua will be treated as server-side script.
Client-Side files are executed from SERVER only! Do NOT include them in fxmanifest!
These files only can access self object after the client side has fully loaded!