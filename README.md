# beef-drive

## Description
This is a special version of [BeEF] (https://github.com/beefproject/beef) implementing all comminications with its zombies via Google Drive service.

At the present time [Browser Exploitation Framework (BeEF)](http://beefproject.com/) supports
[experimental WebRTC-based mechanism](http://blog.beefproject.com/2015/01/hooked-browser-meshed-networks-with.html#more)
for implementing a hooked browser meshed-network.
The main purpose of this solution is avoiding tracking of post-exploitation communication
back to BeEF command and control server. We propose an alternate method to provide more anonymity
and undetectability for BeEF hooked browser communications.
The main idea is to use covert channel communications over known and popular cloud web services, for example Google Drive,
by using it as shared resources between BeEF server and hooked browsers.
In this case there is no direct communication between BeEF server and hooked browsers,
all of them communicate only with Google API servers. The implementation is based on Google Drive
file system primitives and its API.
We consider practical issues of this implementation and show how this can be implemented in BeEF.

