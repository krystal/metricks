require File.expand_path('lib/metricks/version', __dir__)

Gem::Specification.new do |s|
  s.name          = 'metricks'
  s.description   = 'An ActiveRecord backend for recording and gathering metrics'
  s.summary       = s.description
  s.homepage      = 'https://github.com/adamcooke/metricks'
  s.licenses      = ['MIT']
  s.version       = Metricks::VERSION
  s.files         = Dir.glob('{lib,db,app}/**/*')
  s.require_paths = ['lib']
  s.cert_chain    = ['certs/adamcooke.pem']
  s.signing_key   = File.expand_path('~/.gem/signing-key.pem') if $PROGRAM_NAME =~ /gem\z/
  s.authors       = ['Adam Cooke']
  s.email         = ['me@adamcooke.io']
  s.add_runtime_dependency 'activerecord', '>= 5.0', '< 7.0'
  s.add_runtime_dependency 'with_advisory_lock', '>= 4.6', '< 5.0'
end
