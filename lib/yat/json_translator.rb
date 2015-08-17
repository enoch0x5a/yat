module YandexTranslator
  require 'json'

  class JSONTranslator < GenericTranslator

    def getLangs(params = nil)
      response = super(:json, params)
      response = JSON.parse(response.body)
      error_check(response["code"])
      response
    end

    def detect(params)
      raise ArgumentError, "text parameter not specified" unless params.has_key?(:text)

      response = super(:json, params)
      response = JSON.parse(response.body)
      error_check(response["code"])
      response["lang"]
    end

    def translate(params)
      raise ArgumentError, "text parameter not specified" unless params.has_key?(:text)
      raise ArgumentError, "lang parameter not specified" unless params.has_key?(:lang)
      
      response = super(:json, params)
      response = JSON.parse(response.body)
      error_check(response["code"])
      return response["text"].inject {|elm, sum| elm + sum} if response["text"].is_a? Array
      response["text"]
    end
  end
end
