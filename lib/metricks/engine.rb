module Metricks
  class Engine < ::Rails::Engine

    engine_name 'metricks'

    config.metricks = ActiveSupport::OrderedOptions.new
    config.metricks.with_lock = nil

    initializer 'metricks.initialize' do |app|
      ActiveSupport.on_load :active_record do
        require 'metricks/models/metric'

        Metricks::Lock.with_lock = app.config.metricks.with_lock
        Metricks::Lock.validate!
      end
    end

  end
end
