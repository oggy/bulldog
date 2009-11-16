module Bulldog
  class Reflection
    def initialize(model_class, name)
      @model_class = model_class
      @name = name

      @path_template = nil
      @url_template = nil
      @styles = StyleSet.new
      @default_style = :original
      @stored_attributes = {}
      @events = Hash.new{|h,k| h[k] = []}
      @type = nil
      @type_detector = nil
    end

    def initialize_copy(other)
      super
      instance_variables.each do |name|
        value = instance_variable_get(name)
        value = value.clone if value.duplicable?
        instance_variable_set(name, value)
      end
    end

    attr_accessor :model_class, :name, :path_template, :url_template, :styles, :events, :stored_attributes, :type, :type_detector
    attr_writer :default_style, :path_template, :url_template

    #
    # Append the given block to this attachment's configuration.
    #
    # Using this, you may specialize an attachment's configuration in
    # a piecemeal fashion; for subclassing, for example.
    #
    def configure(&block)
      Configuration.configure(self, &block) if block
    end

    def default_style
      styles[@default_style] or
        raise Error, "invalid default_style: #{@default_style.inspect}"
      @default_style
    end

    def path_template
      @path_template || Bulldog.default_path_template || File.join(':public_path', url_template)
    end

    def url_template
      @url_template || Bulldog.default_url_template
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

    def self.named_type_detectors
      @named_type_detectors ||= {}
    end

    def self.to_detect_type_by(name, &block)
      named_type_detectors[name] = block
    end

    def self.reset_type_detectors
      named_type_detectors.clear
    end

    to_detect_type_by :default do |record, name, stream|
      if stream
        case stream.content_type
        when %r'\Aimage/'
          :image
        when %r'\Avideo/'
          :video
        when %r'\Aapplication/pdf'
          :pdf
        end
      end
    end

    #
    # Return the attachment type to use for the given record and
    # stream.
    #
    def detect_attachment_type(record, stream)
      return type if type
      detector = type_detector || :default
      if detector.is_a?(Symbol)
        detector = self.class.named_type_detectors[detector]
      end
      detector.call(record, name, stream)
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
      # Options:
      #
      #   * :types - A list of attachment types to process on.  If
      #     nil, process on any type.
      #   * :on - The name of the event to run the processor on.
      #   * :after - Same as prepending 'after_' to the given event.
      #   * :before - Same as prepending 'before_' to the given event.
      #   * :with - Use the given processor type.  If nil (the
      #     default), use the default type for the attachment.
      #
      def process(options={}, &callback)
        event_name = event_name(options)
        types = Array(options[:types]) if options[:types]
        @reflection.events[event_name] << Event.new(:processor_type => options[:with],
                                                    :attachment_types => types,
                                                    :styles => options[:styles],
                                                    :callback => callback)
      end

      def process_once(options={}, &callback)
        options[:with] and
          raise ArgumentError, "cannot specify a processor (:with option) with #process_once"
        options[:styles] and
          raise ArgumentError, "no :styles available for #process_once"
        options[:with] = :one_shot
        process(options, &callback)
      end

      def store_attributes(*args)
        stored_attributes = args.extract_options!.symbolize_keys
        args.each do |attribute|
          stored_attributes[attribute] = :"#{@reflection.name}_#{attribute}"
        end
        @reflection.stored_attributes = stored_attributes
      end

      #
      # Always use the given attachment type for this attachment.
      #
      # This is equivalent to:
      #
      #     detect_type_by do
      #       type if stream
      #     end
      #
      def type(type)
        @reflection.type = type
        @reflection.type_detector = nil
      end

      #
      # Specify a procedure to run to determine the type of the
      # attachment.
      #
      # Pass either:
      #
      #   * A symbol argument, which names a named type detector.  Use
      #    +Bulldog.to_detect_type_by+ to register custom named type
      #    detectors.
      #
      #   * A block, which takes the record, attribute name, and
      #     Stream being assigned, and returns the attachment type to
      #     use as a Symbol.
      #
      #   * A callable object, e.g. a Proc or BoundMethod, which has
      #     the same signature as the block above.
      #
      def detect_type_by(detector=nil, &block)
        detector && block and
          raise ArgumentError, "cannot pass argument and a block"
        @reflection.type = nil
        @reflection.type_detector = detector || block
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
