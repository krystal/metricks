module Metricks
  class Error < StandardError
    attr_reader :code
    attr_reader :message

    def initialize(code, message: nil)
      @code = code
      @message = message
    end

    def to_s
      "[#{@code}] #{@message}"
    end
  end
end
