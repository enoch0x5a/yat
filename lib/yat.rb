TRANSLATOR_PATH = File.dirname(__FILE__) + "/yat/"

['generic', 'json', 'xml'].each { |f| require TRANSLATOR_PATH + "#{f}_translator" }
require TRANSLATOR_PATH + "config"
require TRANSLATOR_PATH + "errors"
