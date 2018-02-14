require 'rest_client'
#require 'restclient/components'
#require 'rack/cache'

module Mei
  module WebServiceBase
    attr_accessor :raw_response

    # mix-in to retreive and parse JSON content from the web
    def get_json(url)
      #RestClient.enable Rack::Cache
      r = RestClient.get url, request_options
      #RestClient.disable Rack::Cache
      JSON.parse(r)

    end

    def request_options
      { accept: :json }
    end

    def get_xml(url)
      #RestClient.enable Rack::Cache
      r = RestClient.get url
      #RestClient.disable Rack::Cache
      r
    end



  end
end
