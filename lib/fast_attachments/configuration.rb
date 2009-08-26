module FastAttachments
  class Configuration
    def initialize(klass, name, type)
      @class = klass
      @name = name
      @type = type
      @options = {}
      @styles = StyleSet.new
      @events = Hash.new{|h,k| h[k] = []}
      @file_attributes = default_file_attributes
    end

    attr_reader :class, :name, :type, :options, :styles, :events, :file_attributes

    def style(name, attributes)
      styles << Style.new(name, attributes)
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