require 'rexml/document'

module YandexTranslator
  class XMLParser
    include Celluloid
    include Celluloid::Notifications
    include REXML

    def parse(text, index)
      xmldoc = REXML::Document.new(text)
      response = Hash.new

      if error = xmldoc.elements["Error"]
        response["code"] = error.attributes['code'].to_i
        response["message"] = error.attributes['message']
      end

      unless (element = xmldoc.elements["Langs/dirs"]).nil?
        response["dirs"] = element.collect { |e|
          e.text
        }
      end

      unless (element = xmldoc.root.attributes["lang"]).nil?
        response["lang"] = element
      end
      unless (element = xmldoc.elements["Langs/langs"]).nil?
        response["langs"] = Hash.new 
        element.each { |e|
          response["langs"][e.attributes["key"]] = e.attributes["value"]
        }
      end
      unless (element = xmldoc.elements["Translation/text"]).nil?
        response["text"] = element.text
      end

      publish(:parsing_done, response, index)
    end
  end
end