$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'active_record'
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
ActiveRecord::MigrationContext.new(File.expand_path('../db/migrate', __dir__)).migrate

require 'metricks'
require_relative './example_types'

RSpec.configure do |config|
  config.after(:each) do
    Metricks::Models::Metric.delete_all
  end
end
