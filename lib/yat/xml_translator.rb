module YandexTranslator
  require 'rexml/document'
  include REXML

  class XMLTranslator < GenericTranslator

    def getLangs(params = nil)

      response = super(:xml, params)

      xmldoc = REXML::Document.new(response.body)

      if error = xmldoc.elements["Error"]
        error_check(error.attributes['code'])
      end

      response = Hash.new
      response["dirs"] = xmldoc.elements["Langs/dirs"].collect { |e|
        e.text
      }
      unless (langs = xmldoc.elements["Langs/langs"]).nil?
        response["langs"] = Hash.new 
        langs.each {|e|
          response["langs"][e.attributes["key"]] = e.attributes["value"]
        }
      end
      response
    end

    def detect(params)

      raise ArgumentError, "text parameter not specified" unless params.has_key?(:text)

      response = super(:xml, params)
      xmldoc = REXML::Document.new(response.body)

      if error = xmldoc.elements["Error"]
        error_check(error.attributes['code'])
      end

      xmldoc.root.attributes["lang"]
    end

    def translate(params)

      raise ArgumentError, "text parameter not specified" unless params.has_key?(:text)
      raise ArgumentError, "lang parameter not specified" unless params.has_key?(:lang)

      response = super(:xml, params)
      xmldoc = REXML::Document.new(response.body)

      if error = xmldoc.elements["Error"]
        error_check(error.attributes['code'])
      end

      xmldoc.elements["Translation/text"].text
    end
  end  #  class XMLTranslator
end