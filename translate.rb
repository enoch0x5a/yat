# -*- encoding: utf-8 -*-
require 'net/http'

class ReturnCodeException < Exception; end

class GenericTranslator
  def initialize
    require_relative 'config.rb'
  end

  def getLangs(return_as, params)
    make_request(:getLangs, return_as, params)
  end

  def detect(return_as, params)
    make_request(:detect, return_as, params)
  end

  def translate(return_as, params)
    make_request(:translate, return_as, params)
  end

  def make_request(function, format, params)
    if not [:json, :xml].member? format
      raise ArgumentError, "wrong format: #{format}"
    end
    uri = URI(Options["#{format}_path".to_sym])
    uri.path += "/#{function}"
    uri.query = URI.encode_www_form( {:key => Options[:key] }.merge params)
    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https') do |https|
      request = Net::HTTP::Post.new(uri)
      response = https.request(request)
    end
  end

  def parse_code(code)
    code = code.to_i if code.respond_to? :to_i
    if !code.nil? && code != 200  #getLangs won't return 200:OK for now :_(
      raise ReturnCodeException, case code
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

  alias :generic_getLangs :getLangs
  def getLangs(params)
    response = generic_getLangs(:json, params)
    response = JSON.parse(response.body)
    parse_code(response["code"])
    response
  end

  alias :generic_detect :detect
  def detect(params)
    response = generic_detect(:json, params)
    response = JSON.parse(response.body)
    parse_code(response["code"])
    response
  end

  alias :generic_translate :translate
  def translate(params)
    response = generic_translate(:json, params)
    response = JSON.parse(response.body)
    parse_code(response["code"])
    response
  end
end #  class JSONTranslator


require 'rexml/document'
include REXML

class XMLTranslator < GenericTranslator
  alias :generic_getLangs :getLangs
  def getLangs(params)
    response = generic_getLangs(:xml, params)

    xmldoc = Document.new(response.body)

    if error = xmldoc.elements["Error"]
      parse_code(error.attributes['code'])
    end

    response = Hash.new
    response["dirs"] = xmldoc.elements["Langs/dirs"].collect {|e|
      e.text
    }
    response["langs"] = Hash.new
    xmldoc.elements["Langs/langs"].each {|e|
      response["langs"][e.attributes["key"]] = e.attributes["value"]
    }
    response
  end

  alias :generic_detect :detect
  def detect(params)
    response = generic_detect(:xml, params)
    xmldoc = Document.new(response.body)

    if error = xmldoc.elements["Error"]
      parse_code(error.attributes['code'])
    end

    response = Hash.new
    response["code"] = xmldoc.root.attributes["code"]
    response["lang"] = xmldoc.root.attributes["lang"]

    response
  end

  alias :generic_translate :translate
  def translate(params)
    response = generic_translate(:xml, params)
    xmldoc = Document.new(response.body)

    if error = xmldoc.elements["Error"]
      parse_code(error.attributes['code'])
    end

    response = Hash.new
    response["code"] = xmldoc.root.attributes["code"]
    response["lang"] = xmldoc.root.attributes["lang"]
    response["text"] = xmldoc.elements["Translation/text"].text

    response
  end
end  #  class XMLTranslator

translator = XMLTranslator.new

res = translator.getLangs(:ui => 'ru')

res = translator.detect(:text => 'текст')

res = translator.translate(:text => 'тестовый текст', :lang => 'en')
