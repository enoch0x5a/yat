module YandexTranslator
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(self.configuration) rescue self.configuration
  end

  class Configuration
    attr_accessor :api_key, :xml_path, :json_path, :host, :port, :chunk_size, :maximum_requests

    def initialize
      @chunk_size = 10000
      @maximum_requests = 10
      @api_key = nil
      @host = "https://translate.yandex.net"
      @json_path = '/api/v1.5/tr.json'
      @xml_path = '/api/v1.5/tr'
    end
  end

end
