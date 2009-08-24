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

    def before(event, &block)
      on("before_#{event}".to_sym, &block)
    end

    def after(event, &block)
      on("after_#{event}".to_sym, &block)
    end

    def process(record, event, *args)
      callback = events[event] or
        return
      processor = Processor.class_for(type).new(record)
      processor.instance_exec(*args, &callback)
    end
  end
end
