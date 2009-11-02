module Bulldog
  class Reflection
    def initialize(model_class, name, &block)
      @model_class = model_class
      @name = name

      @path_template = Bulldog.default_path
      @styles = StyleSet.new
      @default_style = :original
      @stored_attributes = {}
      @events = Hash.new{|h,k| h[k] = []}

      Configuration.configure(self, &block) if block
    end

    attr_accessor :model_class, :name, :path_template, :url_template, :styles, :events, :stored_attributes
    attr_writer :default_style

    def default_style
      styles[@default_style] or
        raise Error, "invalid default_style: #{@default_style.inspect}"
      @default_style
    end

    #
    # Return the column name to use for the named storable attribute.
    #
    def column_name_for_stored_attribute(attribute)
      if stored_attributes.fetch(attribute, :not_nil).nil?
        nil
      elsif (value = stored_attributes[attribute])
        value
      else
        default_column = "#{name}_#{attribute}"
        column_exists = model_class.columns_hash.key?(default_column)
        column_exists ? default_column.to_sym : nil
      end
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

      def store_attributes(*args)
        stored_attributes = args.extract_options!.symbolize_keys
        args.each do |attribute|
          stored_attributes[attribute] = :"#{@reflection.name}_#{attribute}"
        end
        @reflection.stored_attributes = stored_attributes
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
  end
end
