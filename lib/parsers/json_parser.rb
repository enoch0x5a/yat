require 'json'

module YandexTranslator
  class JSONParser
    include Celluloid
    include Celluloid::Notifications

    def parse(text, index)
      response = JSON.parse(text)
      response["text"] = response["text"].inject {|elm, sum| elm + sum} if response["text"].is_a? Array
      publish(:parsing_done, response, index)
    end
  end
end