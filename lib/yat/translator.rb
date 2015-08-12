# -*- encoding: utf-8 -*-
require 'net/http'

module YandexTranslator

  class GenericTranslator
    attr_reader :response

    def initialize
      require_relative 'config.rb'
      @response = nil
    end

private
    def method_missing(api_function, *args)
      format = args.shift
      @response = make_request(api_function, format, *args)
    end

protected

    def make_request(function, format, params = nil)
      raise ArgumentError, "wrong format: #{format}" if YandexTranslator::Options["#{format}_path".to_sym].nil?

      key_hash = {:key => YandexTranslator::Options[:key]}
      params = params.nil? ? key_hash : key_hash.merge(params)
      uri = URI(YandexTranslator::Options["#{format}_path".to_sym])
      uri.path += "/#{function}"
      
      Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') do |https|
        request = Net::HTTP::Post.new(uri)
        @response = https.request(request, URI.encode_www_form(params))
      end
    end

    def error_check(return_code)
      unless return_code.nil? || return_code == 200
        raise YandexTranslator::ReturnCodeException, case return_code.to_i
          when 401
            "401: wrong api key"
          when 402
            "402: api key blocked"
          when 403
            "403: daily request limit exceeded"
          when 404
            "404: daily text volume limit exceeded"
          when 413
            "413: text size too big"
          when 422
            "422: unable to translate"
          when 501
            "501: translation direction is not supported"
        end
      end
    end

  end #  class GenericTranslator

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
  end  #  class JSONTranslator

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
end  #  module YandexTranslator
