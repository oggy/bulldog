module FastAttachments
  class Configuration
    def initialize(klass, name, type)
      @klass = klass
      @name = name
      @type = type
      @options = {}
      @styles = {}
      @events = Hash.new{|h,k| h[k] = []}
    end

    attr_reader :name, :type, :options, :styles, :events

    def style(name, attributes)
      styles[name] = attributes
    end

    def on(event, &block)
      events[event] << block
    end

    def before(event, &block)
      on("before_#{event}".to_sym, &block)
    end

    def after(event, &block)
      on("after_#{event}".to_sym, &block)
    end
  end
end
