module FastAttachments
  class Reflection
    def initialize(klass, name, options)
      @klass = klass
      @name = name
      @options = options
      @styles = {}
      @events = {}
    end

    attr_reader :name, :options, :styles, :events

    def style(name, attributes)
      styles[name] = attributes
    end

    def on(event, &block)
      events[event] = block
    end
  end
end
