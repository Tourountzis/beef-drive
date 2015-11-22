#
# Copyright (c) 2006-2015 Wade Alcorn - wade@bindshell.net
# Browser Exploitation Framework (BeEF) - http://beefproject.com
# See the file 'doc/COPYING' for copying permission
#
module BeEF
module Extension
module Gdrive 

  extend BeEF::API::Extension

  @short_name  = 'Gdrive'
  @full_name   = 'Gdrive hooked-browser'
  @description = '' 

end
end
end

require 'extensions/gdrive/api.rb'
require 'extensions/gdrive/browser-details.rb'
require 'extensions/gdrive/gdrive.rb'
require 'extensions/gdrive/models/gdrive_db'
