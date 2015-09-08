require_relative '../lib/yat'
require 'celluloid/test'
require 'rspec'

raise "provide api key through env variable TRANSLATOR_KEY" if ENV['TRANSLATOR_KEY'].nil?

Celluloid.logger = nil
UNSUPPORTED_LANGUAGE = 'zz'

YandexTranslator::configure { |config| 
  config.api_key = ENV['TRANSLATOR_KEY']
}

shared_examples 'failures' do |translator_format|
  around(:each) do |example|
    Celluloid.boot
    @translator = YandexTranslator::Yat.new(translator_format)
    example.run
    @translator.terminate
    Celluloid.shutdown
  end

  it 'should fail on wrong api key' do
    key = 'worng_api_key'
    key, YandexTranslator::configuration.api_key = YandexTranslator::configuration.api_key, key
    
    expect(@translator.get_languages).to be_nil
    expect(@translator.detect(text: "test")).to be_nil
    expect(@translator.translate(text: "test", lang: "ru")).to be_nil
    YandexTranslator::configuration.api_key = key
  end

  it 'should fail on #detect call without :text specified' do
    expect(@translator.detect({})).to be_nil
  end

  it 'should fail on #translate call without :text specified' do
    expect(@translator.translate(lang: "ru")).to be_nil
  end

  it 'should fail on #translate call without :lang specified' do
    expect(@translator.translate(text: "test text")).to be_nil
  end

  it 'should return error on #translate if unsupported language given' do
    expect(@translator.translate(text: "test text",
      lang: UNSUPPORTED_LANGUAGE)).to be_nil
  end

end

shared_examples 'expected behavior' do |translator_format|
  # around(:each) do |ex|
  #   Celluloid.boot
  #   @translator = YandexTranslator::Yat.new(translator_format)
  #   ex.run
  #   @translator.terminate
  #   Celluloid.shutdown
  # end
  it 'should return translation directions array' do
    expect((@translator.get_languages["dirs"])).to_not be_empty
  end

  it 'should return translation directions array along with langs hash' do
    expect(@translator.get_languages(ui: "ru")["langs"]).to_not be_empty
  end

  it 'should return lang on #detect' do
    expect(@translator.detect(text: "test")["lang"]).to eq('en')
  end

  it "should return 'test text' on #translate" do
    expect(@translator.translate(text: 'тестовый текст', lang: 'en')["text"]).to \
      eq('test text')
  end
end

describe "translator, xml format" do
  translator_format = :xml
  include_examples 'failures', translator_format
  include_examples 'expected behavior', translator_format
end

describe "translator, json format" do
  translator_format = :json
  include_examples 'failures', translator_format
  include_examples 'expected behavior', translator_format
end
