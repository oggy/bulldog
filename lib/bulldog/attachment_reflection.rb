module Bulldog
  class AttachmentReflection
    def initialize(klass, name_with_optional_type, &block)
      parse_arguments(klass, name_with_optional_type)
      configure(&block)
      define_accessors
    end

    attr_accessor :class, :name, :type, :styles, :events, :file_attributes

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
      self.class.attachment_reflections[name] = self
    end

    def define_accessors
      self.class.module_eval <<-EOS, __FILE__, __LINE__
        def #{@name}
          attachment_attribute(:#{@name}).get
          read_attribute(:#{@name})
        end

        def #{@name}=(value)
          process_attachment(:#{@name}, :before_assignment, value)
          attachment_attribute(:#{@name}).set(value)
          process_attachment(:#{@name}, :after_assignment, value)
        end

        def #{@name}?
          !!#{@name}
        end
      EOS
    end
  end
end
