module Bulldog
  class Style < Hash
    def initialize(name, attributes)
      super()
      merge!(attributes)
      @name = name
    end

    attr_reader :name

    # For specs.
    def ==(other)
      other.is_a?(Style) &&
        name == other.name &&
        super
    end

    ORIGINAL = new(:original, {})
  end
end
