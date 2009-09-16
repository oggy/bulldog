module Bulldog
  class Configuration
    def initialize(klass, name)
      @class = klass
      @name = name
      @path_template = Bulldog.default_path
      @options = {}
      @styles = StyleSet.new
      @default_style = :original
      @events = Hash.new{|h,k| h[k] = []}
      @file_attributes = default_file_attributes
    end

    attr_reader :class, :name, :path_template, :url_template, :options, :styles, :events, :file_attributes

    def path(path_template)
      @path_template = path_template
    end

    def url(url_template)
      @url_template = url_template
    end

    def style(name, attributes)
      styles << Style.new(name, attributes)
    end

    def default_style(*args)
      if args.empty?
        @default_style
      else
        name = args.first
        styles.find{|style| style.name == name} or
          raise Error, "invalid style name: #{name.inspect}"
        @default_style = name
      end
    end

    def on(event, options={}, &block)
      const_name = (options[:with] || 'base').to_s.camelize
      processor_class = Processor.const_get(const_name)
      events[event] << [processor_class, block]
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
        hash[name.to_sym] = default_file_attribute_name_for(name)
      end
      @file_attributes = hash
    end

    private  # -------------------------------------------------------

    def default_file_attributes
      file_attributes = {}
      [:file_name, :content_type, :file_size, :updated_at].each do |suffix|
        file_attributes[suffix] = default_file_attribute_name_for(suffix)
      end
      file_attributes
    end

    def default_file_attribute_name_for(suffix)
      column_name = "#{name}_#{suffix}".to_sym
      self.class.columns_hash.key?(column_name.to_s) ? column_name : nil
    end
  end
end
