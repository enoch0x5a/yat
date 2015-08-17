module YandexTranslator
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(self.configuration) rescue self.configuration
  end

  class Configuration
    attr_accessor :api_key, :xml_path, :json_path

    def initialize
      @api_key = nil
      @json_path = 'https://translate.yandex.net/api/v1.5/tr.json'
      @xml_path = 'https://translate.yandex.net/api/v1.5/tr'
    end
  end

end
