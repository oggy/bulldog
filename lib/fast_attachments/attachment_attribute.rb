module FastAttachments
  class AttachmentAttribute
    def initialize(klass, name_with_optional_type, &block)
      parse_arguments(klass, name_with_optional_type)
      configure(&block)
      define_accessors
    end

    attr_reader :class, :name, :type, :styles, :events

    def process(event, *args)
      events[event].each do |callback|
        processor = Processor.class_for(type).new
        processor.process(*args, &callback)
      end
    end

    private  # -------------------------------------------------------

    def parse_arguments(klass, name_with_optional_type)
      @class = klass
      if name_with_optional_type.is_a?(Hash)
        name_with_optional_type.size == 1 or
          raise ArgumentError, "hash argument must have exactly 1 key/value"
        @name, @type = *name_with_optional_type.to_a.first
      else
        @name, @type = name_with_optional_type, nil
      end
    end

    def configure(&block)
      configuration = Configuration.new(self.class, name, type)
      configuration.instance_eval(&block) if block
      @styles = configuration.styles
      @events = configuration.events
      self.class.attachment_attributes[name] = self
    end

    def define_accessors
      self.class.module_eval <<-EOS, __FILE__, __LINE__
        def #{@name}
          attachments[:#{@name}]
        end

        def #{@name}=(value)
          process_attachment(:#{@name}, :before_assignment, value)
          attachments[:#{@name}] = value
          process_attachment(:#{@name}, :after_assignment, value)
        end

        def #{@name}?
          !!attachments[:#{@name}]
        end
      EOS
    end
  end
end
