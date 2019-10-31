require 'metricks/type'

module Metricks
  module Types
    class Evented < Metricks::Type
      def self.cumulative?
        false
      end
    end
  end
end
