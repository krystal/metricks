module Metricks
  class Point
    attr_reader :time
    attr_reader :sum
    attr_reader :count
    attr_reader :last

    def initialize(time:, sum: 0.0, count: 0, last: 0.0)
      @time = time
      @sum = sum
      @count = count
      @last = last
    end
  end
end
