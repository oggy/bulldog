module Bulldog
  class Reflection
    def initialize(klass, name_with_optional_type, &block)
      parse_arguments(klass, name_with_optional_type)
      configure(&block)
    end

    attr_accessor :class, :name, :type, :path_template, :styles, :events, :file_attributes

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
      [:path_template, :styles, :events, :file_attributes].each do |field|
        send("#{field}=", configuration.send(field))
      end
      self.class.attachment_reflections[name] = self
    end
  end
end
