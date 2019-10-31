module Metricks
  class Engine < ::Rails::Engine

    engine_name 'metricks'

    initializer 'metricks.initialize' do |app|
      ActiveSupport.on_load :active_record do
        require 'metricks/models/metric'
      end
    end

  end
end
