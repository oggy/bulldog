module FastAttachments
  class Reflection
    def initialize(klass, name, type)
      @klass = klass
      @name = name
      @type = type
      @options = {}
      @styles = {}
      @events = {}
    end

    attr_reader :name, :type, :options, :styles, :events

    def style(name, attributes)
      styles[name] = attributes
    end

    def on(event, &block)
      events[event] = block
    end
  end
end
