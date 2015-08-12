# -*- encoding: utf-8 -*-
require_relative '../lib/yat'
require 'rspec'

if YandexTranslator::Options[:key].nil?
  p "no api key set" 
  exit!
end

UNSUPPORTED_LANGUAGE = 'zz'

shared_examples 'failures' do |translator|
  it 'should fail on wrong api key' do
    key = 'ttt'
    key, YandexTranslator::Options[:key] = YandexTranslator::Options[:key], key
    expect {translator.getLangs}.to \
      raise_error(YandexTranslator::ReturnCodeException, "401: wrong api key")
    expect {translator.detect(text: "test")}.to \
      raise_error(YandexTranslator::ReturnCodeException, "401: wrong api key")
    expect {translator.translate(text: "test", lang: "ru")}.to \
      raise_error(YandexTranslator::ReturnCodeException, "401: wrong api key")
    YandexTranslator::Options[:key] = key
  end

  it 'should fail on #translate if text > 10k characters' do
    expect { translator.translate(text: "test"*3000, lang:"ru") }.to \
      raise_error(YandexTranslator::ReturnCodeException,
        "413: text size too big")
  end

  it 'should fail on #detect call without :text specified' do
    expect { translator.detect( {} ) }.to \
      raise_error(ArgumentError, "text parameter not specified")
  end

  it 'should fail on #translate call without :text specified' do
    expect { translator.translate(lang: "ru") }.to \
      raise_error(ArgumentError, "text parameter not specified")
  end

  it 'should fail on #translate call without :lang specified' do
    expect { translator.translate(text: "test text") }.to \
      raise_error(ArgumentError, "lang parameter not specified")
  end

  it 'should return error on #translate if unsupported language given' do
    expect { translator.translate(text: "test text",
      lang: UNSUPPORTED_LANGUAGE) }.to \
      raise_error(YandexTranslator::ReturnCodeException, 
        "501: translation direction is not supported")
  end

end

shared_examples 'expected behavior' do |translator|
  it 'should return translation directions array' do
    expect((translator.getLangs["dirs"])).to_not be_empty
  end

  it 'should return translation directions array along with langs hash' do
    expect(translator.getLangs(ui: "ru")["langs"]).to_not be_empty
  end

  it 'should return lang on #detect' do
    expect(translator.detect(text: "test")).to eq('en')
  end

  it "should return 'test text' on #translate" do
    expect(translator.translate(text: 'тестовый текст', lang: 'en')).to \
      eq('test text')
  end
end

# describe YandexTranslator::XMLTranslator do
#   translator = YandexTranslator::XMLTranslator.new
#   include_examples 'failures', translator
#   include_examples 'expected behavior', translator
# end

describe YandexTranslator::JSONTranslator do
  translator = YandexTranslator::JSONTranslator.new
  # include_examples 'failures', translator
  include_examples 'expected behavior', translator
end
