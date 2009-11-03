module Bulldog
  class Reflection
    def initialize(model_class, name, &block)
      @model_class = model_class
      @name = name

      @default_path_template = nil
      @default_url_template = nil
      @styles = StyleSet.new
      @default_style = :original
      @stored_attributes = {}
      @events = Hash.new{|h,k| h[k] = []}
      @file_missing_callback = nil

      Configuration.configure(self, &block) if block
    end

    attr_accessor :model_class, :name, :path_template, :url_template, :styles, :events, :stored_attributes, :file_missing_callback
    attr_writer :default_style, :path_template, :url_template

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

      #
      # Specify a dummy file to use for the record when the record
      # exists, but the file does not.
      #
      # The block receives the record, and should return either nil
      # (if the attachment should be considered absent), or the result
      # of a call to #missing_file to specify some dummy file
      # attributes to use.
      #
      #   * #missing_file, to create a dummy file object to use
      #   * #no_file if the attachment should be considered nil
      #
      # Example:
      #
      #     when_file_missing do |record|
      #       case record
      #       when Photo
      #         attach :image
      #       when Video
      #         attach :video
      #       end
      #     end
      #
      # #missing_file takes a mandatory attachment type symbol, and a
      # hash of the following options:
      #
      def when_file_missing(&callback)
        @reflection.file_missing_callback = FileMissingCallback.new(callback)
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

    class FileMissingCallback
      def initialize(callback)
        @callback = callback
      end

      def call(record, name)
        context = Context.new(record, name)
        catch :use_attachment do
          context.instance_eval(&@callback)
          nil
        end
      end

      private  # -----------------------------------------------------

      class Context
        def initialize(record, name)
          @record = record
          @name = name
        end

        attr_reader :record, :name

        def use_attachment(type, options={})
          value = MissingFile.new(options)
          attachment = Attachment.missing(type, record, name, value)
          throw :use_attachment, attachment
        end
      end
    end
  end
end
