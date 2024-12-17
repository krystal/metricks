$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'rails'
require 'active_record'
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

if ActiveRecord::VERSION::MAJOR == 6
  ActiveRecord::MigrationContext.new(File.expand_path('../db/migrate', __dir__), ActiveRecord::SchemaMigration).migrate
else
  ActiveRecord::MigrationContext.new(File.expand_path('../db/migrate', __dir__)).migrate
end

require 'metricks'
require_relative './example_types'

RSpec.configure do |config|
  config.after(:each) do
    Metricks::Models::Metric.delete_all
  end

  config.full_backtrace = true

end
