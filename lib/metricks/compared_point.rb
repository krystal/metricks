require 'metricks/comparison'

module Metricks
  class ComparedPoint
    def initialize(a, b)
      @a = a
      @b = b
    end

    attr_reader :a
    attr_reader :b

    def sum
      Comparison.new(@a.sum, @b.sum)
    end

    def count
      Comparison.new(@a.count, @b.count)
    end

    def last
      Comparison.new(@a.last, @b.last)
    end
  end
end
