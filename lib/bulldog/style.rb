module Bulldog
  #
  # Represents a style to generate.
  #
  class Style
    def initialize(name, attributes={})
      @name = name
      @attributes = attributes
      set_dimensions(attributes[:size])
    end

    attr_reader :name, :attributes

    #
    # Return the value of the given style attribute.
    #
    delegate :[], :to => :attributes

    #
    # Set the value of the given style attribute.
    #
    def []=(name, value)
      if name == :size
        set_dimensions(value)
      end
      attributes[name] = value
    end

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

    #
    # The [width, height] specified by :size, or nil if there is no :size.
    #
    attr_reader :dimensions

    #
    # Return true if :filled is true, false otherwise.
    #
    def filled?
      !!self[:filled]
    end

    private

    def set_dimensions(value)
      @dimensions = value ? value.scan(/\A(\d+)x(\d+)\z/).first.map{|s| s.to_i} : nil
    end

    ORIGINAL = new(:original, {})
  end
end
