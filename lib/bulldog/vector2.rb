module Bulldog
  class Vector2
    def initialize(object)
      case object
      when Array
        @x, @y = object[0].to_i, object[1].to_i
      when String
        match = /([+-]?\d+)[^-+\d]*([+-]?\d+)/.match(object) or
          raise ArgumentError, "invalid vector: #{object.inspect}"
        @x, @y = match[1].to_i, match[2].to_i
      else
        raise ArgumentError, "cannot convert to vector: #{object.inspect}"
      end
    end

    attr_accessor :x, :y
  end
end
