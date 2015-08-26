Gem::Specification.new do |s|
  s.name        = 'yat'
  s.version     = '0.1.0'
  s.date        = '2015-08-26'
  s.summary     = "yet another yandex translator"
  s.description = "translates using yandex translator api"
  s.authors     = ["enoch0x5a"]
  s.files       = [
    "lib/yat/config.rb",
    "lib/yat/errors.rb",
    "lib/yat/connection.rb",
    "lib/yat/medium.rb",
    "lib/parsers/json_parser.rb",
    "lib/parsers/xml_parser.rb",
    "lib/yat.rb"
  ]
  s.executables << "yat"
  s.license     = 'MIT'
end
