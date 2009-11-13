module Bulldog
  #
  # An ordered set of Styles.
  #
  # Lookup is by style name.
  #
  class StyleSet
    #
    # Create a StyleSet containing the given styles.
    #
    def initialize(styles=[])
      @styles = styles.to_a
    end

    #
    # Create a StyleSet containing the given styles.
    #
    def self.[](*styles)
      new(styles)
    end

    #
    # Return the style with the given name.
    #
    def [](arg)
      if arg.is_a?(Symbol)
        if arg == :original
          Style::ORIGINAL
        else
          @styles.find{|style| style.name == arg}
        end
      else
        @styles[arg]
      end
    end

    #
    # Add the given style to the set.
    #
    def <<(style)
      @styles << style
    end

    #
    # Return true if the given object has the same styles as this one.
    #
    # The argument must have #to_a defined.
    #
    def ==(other)
      other.to_a == @styles
    end

    #
    # Return the list of styles as an Array.
    #
    def to_a
      @styles.dup
    end

    #
    # Return true if there are no styles in the set, false otherwise.
    #
    def empty?
      @styles.empty?
    end

    #
    # Return the style with the given names.
    #
    def slice(*names)
      styles = names.map{|name| self[name]}
      StyleSet[*styles]
    end

    #
    # Clear all styles out of the style set.
    #
    # The original will still be retrievable.
    #
    def clear
      @styles.clear
    end

    #
    # Yield each style.
    #
    def each(&block)
      @styles.each(&block)
    end

    include Enumerable
  end
end
