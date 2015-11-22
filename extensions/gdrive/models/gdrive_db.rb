module BeEF
  module Core
    module Gdrive
      module Models
        class Custodian

          include DataMapper::Resource

          storage_names[:default] = 'core_gdirve_channel'

          property :id, Serial
          property :session, Text
          property :folder_name, Text
        end
      end
    end
  end
end
