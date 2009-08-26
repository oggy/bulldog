module FastAttachments
  class Style < Hash
    def initialize(name, attributes)
      super()
      merge!(attributes)
      @name = name
    end

    attr_reader :name

    def output_file
      # TODO: substitutions a la paperclip
      self[:path]
    end

    # For specs.
    def ==(other)
      other.is_a?(Style) &&
        name == other.name &&
        super
    end
  end
end
