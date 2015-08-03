# -*- encoding: utf-8 -*-
require 'net/http'
require 'json'

LOCATION = 'https://translate.yandex.net/api/v1.5/tr.json'
API_KEY = 
  'trnsl.1.1.20150727T094607Z.fa989f7cb7c98817.' \
  'f0abcceb21d32fa734cdcba406cfc78053f78484'
class GenericTranslator
  def getLangs(params)
    make_request(:getLangs, params)
  end

  def detect(params)
    make_request(:detect, params)
  end

  def translate(params)
    make_request(:translate, params)
  end

  def make_request(function, params)
    uri = URI(LOCATION)
    uri.path += "/#{function}"
    uri.query = URI.encode_www_form(params)
    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https') do |https|
      request = Net::HTTP::Post.new(uri)
      response = https.request(request)
    end
  end
end

class JSONTranslator < GenericTranslator
  def initialize
    include_relative 'config.rb'
  end
end

translator = GenericTranslator.new

res = translator.getLangs(:key => API_KEY, :ui => 'ru')

res = translator.detect(:key => API_KEY, :text => 'текст')

res = translator.translate(:key => API_KEY, :text => 'тестовый текст', :lang => 'en')

p res.body
