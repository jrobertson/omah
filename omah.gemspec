Gem::Specification.new do |s|
  s.name = 'omah'
  s.version = '0.7.9'
  s.summary = 'Offline Mail Helper: Stores email messages in a file directory archive'
  s.authors = ['James Robertson']
  s.files = Dir['lib/omah.rb','stylesheet/listing.xsl','stylesheet/listing.css']
  s.add_runtime_dependency('dynarex-daily', '~> 0.2', '>=0.2.8')
  s.add_runtime_dependency('rubyzip', '~> 1.2', '>=1.2.1')
  s.add_runtime_dependency('nokorexi', '~> 0.3', '>=0.3.1')
  s.add_runtime_dependency('novowels', '~> 0.1', '>=0.1.3')
  s.signing_key = '../privatekeys/omah.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/omah'
  s.required_ruby_version = '>= 2.1.2'
end
