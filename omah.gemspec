Gem::Specification.new do |s|
  s.name = 'omah'
  s.version = '0.9.5'
  s.summary = 'Offline Mail Helper: Stores email messages in a file directory archive.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/omah.rb','stylesheet/listing.xsl','stylesheet/listing.css']
  s.add_runtime_dependency('dynarex-daily', '~> 0.4', '>=0.4.1')
  s.add_runtime_dependency('nokorexi', '~> 0.7', '>=0.7.0')
  s.add_runtime_dependency('novowels', '~> 0.1', '>=0.1.3')
  s.signing_key = '../privatekeys/omah.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/omah'
  s.required_ruby_version = '>= 2.1.2'
end
