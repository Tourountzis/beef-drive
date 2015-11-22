#
# Copyright (c) 2006-2015 Wade Alcorn - wade@bindshell.net
# Browser Exploitation Framework (BeEF) - http://beefproject.com
# See the file 'doc/COPYING' for copying permission
#
module BeEF
module Extension
module Gdrive 
module API

  module GdriveH
    BeEF::API::Registrar.instance.register(
            BeEF::Extension::Gdrive::API::GdriveH,
            BeEF::API::Server,
            'mount_handler'
    ) 
    def self.mount_handler( b )
      gd = BeEF::Extension::Gdrive::Gdrive.instance
      gd.start_token_updater
      gd.start_init_server
      gd.start_command_server
      gd.start_data_server
    end
  end

end
end
end
end
