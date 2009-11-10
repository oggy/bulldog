module Bulldog
  class Style < Hash
    def initialize(name, attributes={})
      @name = name
      @attributes = attributes
    end

    attr_reader :name, :attributes

    #
    # Return the value of the given style attribute.
    #
    delegate :[], :to => :attributes

    #
    # Set the value of the given style attribute.
    #
    delegate :[]=, :to => :attributes

    #
    # Return true if the argument is a Style with the same name and
    # attributes.
    #
    def ==(other)
      other.is_a?(self.class) &&
        name == other.name &&
        attributes == other.attributes
    end

    def inspect
      "#<Style #{name.inspect} #{attributes.inspect}>"
    end

    delegate :hash, :eql?, :to => :name

    ORIGINAL = new(:original, {})
  end
end
