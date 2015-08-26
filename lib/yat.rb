TRANSLATOR_PATH = File.dirname(__FILE__) + "/yat/"
PARSER_PATH = File.dirname(__FILE__) + "/parsers/"

require TRANSLATOR_PATH + "medium"
require TRANSLATOR_PATH + "config"
require TRANSLATOR_PATH + "errors"
require TRANSLATOR_PATH + "connection"
require PARSER_PATH + "json_parser"
require PARSER_PATH + "xml_parser"


require 'celluloid/current'

module YandexTranslator
  class Yat
    include Celluloid
    include Celluloid::Notifications

    # finalizer :finalize

    # def finalize
    #   p "i'm dying here!!"
    # end

    def initialize(format = :json)
      subscribe(:translator_ready, :__receive_responses)
      subscribe(:parsing_done, :__return_responses)

      @format = format
      @responses_num = 0
      @counter = 0
      @translator = YandexTranslator::Medium.new_link
      @parse_loop = self.async.parse_loop
    end

    def parse_loop
      loop do 
        responses = wait :got_responses
        responses.each.with_index { |response, index| parser.async.parse(response.body, index) }
      end
    end

    def translate(params)
      raise ArgumentError, "wrong or missing parameters: ':text' #{params}" unless params[:text]
      raise ArgumentError, "wrong or missing parameters: ':lang' #{params}" unless params[:lang]

      @result = []
      @translator.async.translate(@format, params)
      wait :return
      res = Hash.new("")
      res = @result.shift
      if @result
        @result.each do |hash|
          res["text"] += hash["text"]
        end
      end
      res
    end

    def get_languages(params = nil)
      @result = []
      params ||= Hash.new
      @translator.getLangs(@format, params)
      wait :return
      @result
    end

    def detect(params)
      raise ArgumentError, "text parameter missing" unless params[:text]
      @result = []
      @translator.detect(@format, params)
      wait :return
      @result
    end

    def parser
      case @format
      when :json
        JSONParser.new_link
      when :xml
        XMLParser.new_link
      end
    end

    def __return_responses(topic, response, index)

      if response["message"]
        raise YandexTranslator::ReturnCodeException, response["message"]
      end

      @counter += 1
      @result[index] = response

      if @counter == @responses_num
        @responses_num = @counter = 0
        signal :return
      end
    end

    def __receive_responses(topic, responses)
      @responses_num = responses.length
      signal :got_responses, responses
    end
  end
end
