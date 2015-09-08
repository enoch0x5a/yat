TRANSLATOR_PATH = File.dirname(__FILE__) + "/yat/"
PARSER_PATH = File.dirname(__FILE__) + "/parsers/"

require TRANSLATOR_PATH + "medium"
require TRANSLATOR_PATH + "config"
require TRANSLATOR_PATH + "errors"
require TRANSLATOR_PATH + "connection"
require PARSER_PATH + "json_parser"
require PARSER_PATH + "xml_parser"

require 'celluloid/current'
require 'celluloid/logging'

module YandexTranslator
  class Yat
    include Celluloid
    include Celluloid::Notifications
    include Celluloid::Internals::Logger

    finalizer :finalize
    trap_exit :ambulance

    def ambulance(actor, reason)
      warn "#{actor.inspect} died because of #{reason.inspect}" unless reason.nil?
      signal :return
    end

    def finalize
      @parse_loop.terminate
      @translator.terminate if @translator.alive?
    end

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
      unless params[:text]
        error "wrong or missing parameters: ':text'"
        return nil
      end
      unless params[:lang]
        error "wrong or missing parameters: ':lang'"
        return nil
      end

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
      @translator.async.getLangs(@format, params)
      wait :return
      @result.shift
    end

    def detect(params)
      unless params[:text]
        error "text parameter missing"
        return nil
      end
      
      @result = []
      @translator.async.detect(@format, params)
      wait :return
      @result = @result.shift if @result.size == 1
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
        error response["message"]
        @result.push nil
        signal :return
        return
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
