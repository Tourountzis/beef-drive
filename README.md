# beef-drive

## Description
This is a special version of the [BeEF] (https://github.com/beefproject/beef) implementing all communications with its hooked browsers (zombies) via Google Drive service.

At the present time [Browser Exploitation Framework (BeEF)](http://beefproject.com/) implements communications with hooked browsers using standard mechanisms (e.g., XMLHttpRequest, WebSockets). It also supports [experimental WebRTC-based mechanism](http://blog.beefproject.com/2015/01/hooked-browser-meshed-networks-with.html#more)
for creation a hooked browser meshed-network. The main purpose of the last mechanism is avoiding tracking of post-exploitation communication with BeEF command and control server.

We propose to use an alternate approach against tracking of BeEF servers and its post-exploatation communications with zombies.
The main idea is to use storage covert channel communications over known and popular cloud web services, for example Google Drive,
by using it as shared resources between BeEF server and hooked browsers. In this case there is no direct communication between BeEF server and zombies: All of them communicate only with Google API servers. The implementation is based on Google Drive
file system primitives and its API.

### Installation
1. Create an API key and OAuth 2.0 client ID using Google Developers Console.

2. In your Drive create a folder with name `answers` to store answers from zombies, a folder with name `init` to store initial information from zombies, and a file with name `keychain.txt` to store your API key. Save IDs of these folders and file. You can use any names for folders and file. The above names are used as an example only.

3. Clone the [beef-drive](https://github.com/tsu-iscd/beef-drive.git). [Install](https://github.com/beefproject/beef/wiki/Installation) all dependencies that are required for BeEF.

4. Add the IDs from step 2 to the following files:
	* core/main/client/gdrive.js:
    	* `api_key` - Google OAuth2.0 API key
    	* `answers_folder_id` - ID of the `answers` folder
    	* `init_folder_id` - ID of the `init` folder
    	* `keychain_file_id` - ID of the `keychain.txt` file
	
	* extensions/gdrive/gdrive.rb
    	* `client_id` - Google OAuth 2.0 client ID
    	* `refresh_token` - Google OAuth 2.0 refresh token
    	* `client_secret` - Google OAuth 2.0 client's secret
    	* `@@answer_folder_id` - ID of the `answers` folder
    	* `@@init_folder_id` - ID of the `init` folder
    	* `@@key_file_id` - ID of the `keychain.txt` file
5. Run the beef:

	```
 	ruby beef
	```

### Video
The demonstration is available [here](http://www.youtube.com/watch?v=_RfBUEcvynM).

### Links
* [The Browser Exploitation Framework Project] (https://github.com/beefproject/beef)
* [Hooked-Browser Meshed-Networks with WebRTC. Part 1] (http://blog.beefproject.com/2015/01/hooked-browser-meshed-networks-with.html)
* [Hooked-Browser Meshed-Networks with WebRTC. Part 2](http://blog.beefproject.com/2015/01/hooked-browser-meshed-networks-with_26.html)
