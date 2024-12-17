# frozen_string_literal: true`

require File.expand_path('lib/metricks/version', __dir__)

Gem::Specification.new do |gem|
  gem.name          = 'metricks'
  gem.description   = 'An ActiveRecord backend for recording and gathering metrics'
  gem.summary       = gem.description
  gem.homepage      = 'https://github.com/krystal/metricks'
  gem.licenses      = ['MIT']
  gem.version       = Metricks::VERSION
  gem.files         = Dir.glob('{lib,db,app}/**/*')
  gem.require_paths = ['lib']
  gem.authors       = ['Krystal']
  gem.email         = ['help@krystal.uk']
  gem.required_ruby_version = '>= 2.7'
  gem.add_runtime_dependency 'activerecord', '>= 5.0'
end
