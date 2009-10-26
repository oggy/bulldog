module Bulldog
  class Reflection
    def initialize(model_class, name, &block)
      @model_class = model_class
      @name = name

      @type = nil
      @path_template = Bulldog.default_path
      @styles = StyleSet.new
      @default_style = :original
      @file_attributes = default_file_attributes
      @events = Hash.new{|h,k| h[k] = []}

      Configuration.configure(self, &block) if block
      validate_type
    end

    attr_accessor :model_class, :name, :type, :path_template, :url_template, :styles, :events, :file_attributes
    attr_writer :default_style

    def default_style
      styles[@default_style] or
        raise Error, "invalid default_style: #{@default_style.inspect}"
      @default_style
    end

    def attachment_class
      name = type.to_s.camelize
      if Attachment.const_defined?(name)
        Attachment.const_get(name)
      else
        Attachment::Base
      end
    end

    def default_processor_class
      name = type.to_s.camelize
      if Processor.const_defined?(name)
        Processor.const_get(name)
      else
        Processor::Base
      end
    end

    class Configuration
      def self.configure(reflection, &block)
        new(reflection).instance_eval(&block)
      end

      def initialize(reflection)
        @reflection = reflection
      end

      def type(type)
        @reflection.type = type
      end

      def path(path_template)
        @reflection.path_template = path_template
      end

      def url(url_template)
        @reflection.url_template = url_template
      end

      def style(name, attributes)
        @reflection.styles << Style.new(name, attributes)
      end

      def default_style(name)
        @reflection.default_style = name
      end

      def on(event, options={}, &block)
        if options[:with]
          const_name = options[:with].to_s.camelize
          processor_class = Processor.const_get(const_name)
        else
          processor_class = @reflection.default_processor_class
        end
        @reflection.events[event] << [processor_class, block]
      end

      def before(event, options={}, &block)
        on("before_#{event}".to_sym, options, &block)
      end

      def after(event, options={}, &block)
        on("after_#{event}".to_sym, options, &block)
      end

      def store_file_attributes(*args)
        hash = args.extract_options!.symbolize_keys
        args.each do |name|
          hash[name.to_sym] = @reflection.send(:default_file_attribute_name_for, name)
        end
        @reflection.file_attributes = hash
      end
    end

    private  # -------------------------------------------------------

    def validate_type
      @type or
        raise ConfigurationError, "please specify a type - e.g., type(:image)"
    end

    def default_file_attributes
      file_attributes = {}
      [:file_name, :content_type, :file_size, :updated_at].each do |suffix|
        file_attributes[suffix] = default_file_attribute_name_for(suffix)
      end
      file_attributes
    end

    def default_file_attribute_name_for(suffix)
      column_name = "#{name}_#{suffix}".to_sym
      model_class.columns_hash.key?(column_name.to_s) ? column_name : nil
    end
  end
end
