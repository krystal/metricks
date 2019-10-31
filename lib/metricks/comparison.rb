module Metricks
  class Comparison
    attr_reader :a
    attr_reader :b

    def initialize(a, b)
      @a = a
      @b = b
    end

    def difference
      @a - @b
    end

    def percentage_change
      diff = (@a - @b)
      return 0 if diff.zero?
      return nil if @b.zero?

      diff / @b.to_f * 100.0
    end
  end
end
