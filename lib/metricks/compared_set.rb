require 'metricks/compared_point'

module Metricks
  class ComparedSet
    def initialize(a, b)
      @a = a
      @b = b

      @points = []
      @a.filled.each_with_index do |point, i|
        @points << ComparedPoint.new(point, @b.filled[i])
      end
    end

    attr_reader :a
    attr_reader :b
    attr_reader :points
  end
end
