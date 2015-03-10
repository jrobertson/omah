Gem::Specification.new do |s|
  s.name = 'omah'
  s.version = '0.2.0'
  s.summary = 'Offline Mail Helper: Stores email messages in a file directory archive'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_runtime_dependency('dynarex-daily', '~> 0.1', '>=0.1.12')
  s.signing_key = '../privatekeys/omah.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/omah'
  s.required_ruby_version = '>= 2.1.2'
end
