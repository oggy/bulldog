module Bulldog
  class Reflection
    def initialize(model_class, name, &block)
      @model_class = model_class
      @name = name

      @path_template = Bulldog.default_path
      @styles = StyleSet.new
      @default_style = :original
      @file_attributes = default_file_attributes
      @events = Hash.new{|h,k| h[k] = []}

      Configuration.configure(self, &block) if block
    end

    attr_accessor :model_class, :name, :path_template, :url_template, :styles, :events, :file_attributes
    attr_writer :default_style

    def default_style
      styles[@default_style] or
        raise Error, "invalid default_style: #{@default_style.inspect}"
      @default_style
    end

    class Configuration
      def self.configure(reflection, &block)
        new(reflection).instance_eval(&block)
      end

      def initialize(reflection)
        @reflection = reflection
      end

      def path(path_template)
        @reflection.path_template = path_template
      end

      def url(url_template)
        @reflection.url_template = url_template
      end

      def style(name, attributes={})
        @reflection.styles << Style.new(name, attributes)
      end

      def default_style(name)
        @reflection.default_style = name
      end

      #
      # Register the callback to fire for the given types of
      # attachments.
      #
      # +types+ is a single attribute type, or a list of them.  e.g.,
      # process(:image) means to run the processor for images only.
      # If +types+ is omitted, the processor is run for all attachment
      # types.
      #
      # Options:
      #
      #   * :on - The name of the event to run the processor on.
      #   * :after - Same as prepending 'after_' to the given event.
      #   * :before - Same as prepending 'before_' to the given event.
      #   * :with - Use the given processor type.  If nil (the
      #     default), use the default type for the attachment.
      #
      def process(*types, &callback)
        options = types.extract_options!
        types = [:base] if types.empty?
        event_name = event_name(options)
        @reflection.events[event_name] << Event.new(:processor_type => options[:with],
                                                    :attachment_types => Array(types),
                                                    :styles => options[:styles],
                                                    :callback => callback)
      end

      def store_file_attributes(*args)
        hash = args.extract_options!.symbolize_keys
        args.each do |name|
          hash[name.to_sym] = @reflection.send(:default_file_attribute_name_for, name)
        end
        @reflection.file_attributes = hash
      end

      private  # -----------------------------------------------------

      def event_name(options)
        name = options[:on] and
          return name
        name = options[:after] and
          return :"after_#{name}"
        name = options[:before] and
          return :"before_#{name}"
        nil
      end
    end

    class Event
      def initialize(attributes={})
        attributes.each do |name, value|
          send("#{name}=", value)
        end
      end

      attr_accessor :processor_type, :attachment_types, :styles, :callback
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
      model_class.columns_hash.key?(column_name.to_s) ? column_name : nil
    end
  end
end
