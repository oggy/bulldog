module Bulldog
  module Attachment
    #
    # Abstract base class of None and Base.
    #
    class Maybe
      def initialize(record, name, stream)
        @record = record
        @name = name
        @stream = stream
        @value = stream && stream.target
        @saved = value.is_a?(SavedFile)
      end

      attr_reader :record, :name, :stream, :value

      #
      # Return true if the original file for this attachment has been
      # saved.
      #
      def saved?
        @saved
      end

      #
      # Set the saved flag.
      #
      attr_writer :saved

      #
      # Return the reflection for the attachment.
      #
      def reflection
        @reflection ||= record.attachment_reflection_for(name)
      end

      #
      # Return true if this object wraps the same IO, and is in the
      # same state as the given Attachment.
      #
      def ==(other)
        record == other.record &&
          name == other.name &&
          value == other.value &&
          saved? == other.saved?
      end

      #
      # Set the stored attributes in the record.
      #
      def set_stored_attributes
        storable_attributes.each do |name, storable_attribute|
          if (column_name = reflection.column_name_for_stored_attribute(name))
            value = storable_attribute.value_for(self, :original)
            record.send("#{column_name}=", value)
          end
        end
      end

      #
      # Clear the stored attributes in the record.
      #
      def clear_stored_attributes
        storable_attributes.each do |name, callback|
          if (column_name = reflection.column_name_for_stored_attribute(name))
            record.send("#{column_name}=", nil)
          end
        end
      end

      #
      # Set the stored attributes in the attachment from the values in
      # the record.
      #
      def read_storable_attributes
        storable_attributes.each do |name, storable_attribute|
          if (column_name = reflection.column_name_for_stored_attribute(name))
            value = record.send(column_name)
            value = send("deserialize_#{name}", value) if storable_attribute.cast
            ivar = :"@#{name}"
            if storable_attribute.per_style?
              instance_variable_get(ivar) or
                instance_variable_set(ivar, {})
              instance_variable_get(ivar)[name] = value
            else
              instance_variable_set(ivar, value)
            end
          end
        end
      end

      protected  # ---------------------------------------------------

      #
      # Return the path that the given style would be stored at.
      #
      # Unlike #path, this is not affected by whether or not the
      # record is saved.  It may depend on the attachment value,
      # however, as some interpolations may be derived from the value
      # assigned to the attachment (e.g., :extension).
      #
      def interpolate_path(style_name)
        template = reflection.path_template
        style = reflection.styles[style_name]
        path = Interpolation.interpolate(template, record, name, style)

        # if a style format is given, override the extension
        if style[:format]
          path.sub!(%r'\.[^/.]*$', ".#{style[:format]}")  #'
        end
        path
      end

      #
      # Return the URL that the given style would be found at.
      #
      # Unlike #url, this is not affected by whether or not the record
      # is saved.  It may be depend on the attachment value, however,
      # as some interpolations may be derived from the value assigned
      # to the attachment (e.g., :extension).
      #
      def interpolate_url(style_name)
        if reflection.url_template
          template = reflection.url_template
        elsif reflection.path_template =~ /\A:rails_root\/public/
          template = $'
        else
          raise "cannot infer url from path - please set the #url for the :#{name} attachment"
        end
        style = reflection.styles[style_name]
        Interpolation.interpolate(template, record, name, style)
      end

      #
      # Declare the given attribute as storable via
      # Bulldog::Reflection::Configuration#store_attributes.
      #
      # Options:
      #
      #  * <tt>:per_style</tt> - the attribute has a different value
      #    for each style.  The access method takes a style name as an
      #    argument to select which one to return, and defaults to the
      #    attribute's default_style.  Only :original is stored, and
      #    loaded after reading.
      #
      #  * <tt>:memoize</tt> - memoize the value.
      #
      #  * <tt>:cast</tt> - run the value through a serialize method
      #    before storing it in the database, and an unserialize
      #    method before initializing the attribute from the raw
      #    database value.  The methods must be called
      #    #serialize_ATTRIBUTE and #unserialize_ATTRIBUTE.
      #
      def self.storable_attribute(name, options={}, &block)
        params = {
          :name => name,
          :callback => block || name,
        }.merge(options)
        storable_attributes[name] = StorableAttribute.new(params)

        if options[:memoize]
          if options[:per_style]
            class_eval <<-EOS, __FILE__, __LINE__+1
              def #{name}_with_memoization(style_name=nil)
                style_name ||= reflection.default_style
                memoized_#{name}[style_name] ||= #{name}_without_memoization(style_name)
              end
              def memoized_#{name}
                @#{name} ||= {}
              end
            EOS
          else
            class_eval <<-EOS, __FILE__, __LINE__+1
              def #{name}_with_memoization
                @#{name} ||= #{name}_without_memoization
              end
            EOS
          end
          alias_method_chain name, :memoization
        end
      end

      #
      # The list of storable attributes for this class.
      #
      class_inheritable_accessor :storable_attributes
      self.storable_attributes = {}

      class StorableAttribute
        def initialize(attributes)
          attributes.each do |name, value|
            send("#{name}=", value)
          end
        end

        def value_for(attachment, style_name)
          value =
            if callback.is_a?(Proc)
              callback.call(attachment)
            else
              if per_style?
                attachment.send(callback, style_name)
              else
                attachment.send(callback)
              end
            end
          value = attachment.send("serialize_#{name}", value) if cast
          value
        end

        attr_accessor :name, :callback, :per_style, :memoize, :cast

        alias cast? cast
        alias per_style? per_style
        alias memoize? memoize
      end

      #
      # Remove the files for this attachment, along with any parent
      # directories.
      #
      def delete_files_and_empty_parent_directories
        style_names = reflection.styles.map{|style| style.name} << :original
        style_names.each do |style_name|
          path = interpolate_path(style_name) or
            next
          FileUtils.rm_f(path)
          begin
            loop do
              path = File.dirname(path)
              FileUtils.rmdir(path)
            end
          rescue Errno::EEXIST, Errno::ENOTEMPTY, Errno::ENOENT, Errno::EINVAL, Errno::ENOTDIR
            # Can't delete any further.
          end
        end
      end
    end
  end
end
