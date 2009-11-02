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
        @saved = value.is_a?(UnopenedFile)
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
        Interpolation.interpolate(template, record, name, style)
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
      # Set the named file attribute to the value yielded by the
      # block.  The block is not called unless the file attribute is
      # to be set.
      #
      def set_file_attribute(file_attribute)
        if (column_name = reflection.file_attributes[file_attribute])
          record.send("#{column_name}=", yield)
        end
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
