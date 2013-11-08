Gem::Specification.new do |s|
  s.name = 'omah'
  s.version = '0.1.2'
  s.summary = 'Offline Mail Helper: Stores email messages in a file directory archive'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('dynarex-daily')
  s.signing_key = '../privatekeys/omah.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/omah'
end
