require 'net/http'
require 'celluloid/current'

module YandexTranslator
  
  class Connection
    include Celluloid
    include Celluloid::Notifications
    
    # finalizer :finalize

    # def finalize
    #   p "connection dead!"
    # end

    def initialize
      uri = URI(YandexTranslator::configuration.host)
      @session = Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https')
    end
    
    def request(uri, request_index, params = nil)
      response = @session.request(Net::HTTP::Post.new(uri),
        req = URI.encode_www_form(params || {}))

      publish(:connection_response, request_index, response)
    end
  end
end