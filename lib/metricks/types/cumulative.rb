require 'metricks/type'

module Metricks
  module Types
    class Cumulative < Metricks::Type
      def self.cumulative?
        true
      end
    end
  end
end
