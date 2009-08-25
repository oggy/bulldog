module FastAttachments
  class AttachmentAttribute
    def initialize(klass, name_with_optional_type, &block)
      parse_arguments(klass, name_with_optional_type)
      configure(&block)
      define_accessors
    end

    attr_accessor :class, :name, :type, :styles, :events, :file_attributes

    def process(event, *args)
      events[event].each do |callback|
        processor = Processor.class_for(type).new
        processor.process(*args, &callback)
      end
    end

    def set_value(record, value)
      @record
    end

    def set_file_attributes(record, io)
      set_file_attribute(record, :file_name){io.original_path}
      set_file_attribute(record, :content_type){io.content_type}
      set_file_attribute(record, :file_size){'TODO'}
      set_file_attribute(record, :updated_at){Time.now}
    end

    def set_file_attribute(record, name, &block)
      if (column_name = file_attributes[name])
        record.send("#{column_name}=", yield)
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
      [:styles, :events, :file_attributes].each do |field|
        send("#{field}=", configuration.send(field))
      end
      self.class.attachment_attributes[name] = self
    end

    def define_accessors
      self.class.module_eval <<-EOS, __FILE__, __LINE__
        def #{@name}
          read_attribute(:#{@name})
        end

        def #{@name}=(value)
          process_attachment(:#{@name}, :before_assignment, value)
          write_attribute(:#{@name}, value)
          attachment_attributes[:#{@name}].set_file_attributes(self, value)
          process_attachment(:#{@name}, :after_assignment, value)
        end

        def #{@name}?
          !!#{@name}
        end
      EOS
    end
  end
end
