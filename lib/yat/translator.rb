# -*- encoding: utf-8 -*-
require 'net/http'

module YandexTranslator
  FORMAT_ARRAY = [:xml, :json]

  class GenericTranslator
    attr_reader :response

    def initialize
      require_relative 'config.rb'
    end

    def getLangs(return_as, params)
      response = make_request(:getLangs, return_as, params)
      @response = response.body
      response
    end

    def detect(return_as, params)
      response = make_request(:detect, return_as, params)
      @response = response.body
      response
    end

    def translate(return_as, params)
      response = make_request(:translate, return_as, params)
      @response = response.body
      response
    end

protected
    def make_request(function, format, params)
      if not FORMAT_ARRAY.member? format
        raise ArgumentError, "wrong format: #{format}"
      end
      key_hash = {:key => YandexTranslator::Options[:key]}
      params = params.nil? ? key_hash : key_hash.merge(params)
      uri = URI(Options["#{format}_path".to_sym])
      uri.path += "/#{function}"
      uri.query = URI.encode_www_form(params)
      Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') do |https|
        request = Net::HTTP::Post.new(uri)
        response = https.request(request)
      end
    end

    def error_check(return_code)
      return_code = return_code.to_i if return_code.respond_to? :to_i
      unless return_code.nil? && return_code == 200  #getLangs won't return 200:OK for now :_(
        raise YandexTranslator::ReturnCodeException, case return_code
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

      # response = Hash.new
      # response["code"] = xmldoc.root.attributes["code"]
      # response["lang"] = xmldoc.root.attributes["lang"]

      # response
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

      # response = Hash.new
      # response["code"] = xmldoc.root.attributes["code"]
      # response["lang"] = xmldoc.root.attributes["lang"]
      # response["text"] = xmldoc.elements["Translation/text"].text
      xmldoc.elements["Translation/text"].text

      # response
    end
  end  #  class XMLTranslator
end  #  module YandexTranslator
