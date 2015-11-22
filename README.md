# beef-drive

## Description
This is a special version of [BeEF] (https://github.com/beefproject/beef) implementing all comminications with its zombies via Google Drive service.

At the present time [Browser Exploitation Framework (BeEF)](http://beefproject.com/) implements communications with hooked browsers (zombies) using standard mechanisms (e.g., XMLHttpRequest, WebSockets). It also supports [experimental WebRTC-based mechanism](http://blog.beefproject.com/2015/01/hooked-browser-meshed-networks-with.html#more)
for creation a hooked browser meshed-network. The main purpose of the last mechanism is avoiding tracking of post-exploitation communication back to BeEF command and control server.

We propose to use an alternate approach against tracking of BeEF servers and its post-exploatation communications with zombies.
The main idea is to use covert channel communications over known and popular cloud web services, for example Google Drive,
by using it as shared resources between BeEF server and hooked browsers. In this case there is no direct communication between BeEF server and zombies: All of them communicate only with Google API servers. The implementation is based on Google Drive
file system primitives and its API.

### Video
The demonstration is available [here](http://www.youtube.com/watch?v=_RfBUEcvynM)

### Links
* [Hooked-Browser Meshed-Networks with WebRTC. Part 1] (http://blog.beefproject.com/2015/01/hooked-browser-meshed-networks-with.html)
* [Hooked-Browser Meshed-Networks with WebRTC. Part 2](http://blog.beefproject.com/2015/01/hooked-browser-meshed-networks-with_26.html)


