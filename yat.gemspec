Gem::Specification.new do |s|
  s.name        = 'yat'
  s.version     = '0.0.1'
  s.date        = '2015-08-04'
  s.summary     = "yet another yandex translator"
  s.description = "translates text files using yandex translator api"
  s.authors     = ["enoch0x5a"]
  s.files       = [
    "lib/yat/config.rb",
    "lib/yat/errors.rb",
    "lib/yat/translator.rb",
    "lib/yat.rb"
]
  s.executables << "yat"
  s.license     = 'MIT'
end
