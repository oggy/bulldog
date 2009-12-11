module Bulldog
  module Attachment
    class Base < Maybe
      #
      # Return an instance of the record if the stream is valid, nil
      # otherwise.
      #
      def self.try(record, name, stream)
        attachment = new(record, name, stream)
        attachment.send(:examine) ? attachment : nil
      end

      def initialize(record, name, stream)
        @record = record
        @name = name
        @stream = stream
        @value = stream && stream.target
        @examination_result = nil
      end

      #
      # Run the processors for the named event.
      #
      # Return true if no errors were encountered, false otherwise.
      #
      def process(event_name, options={})
        reflection.events[event_name].each do |event|
          if (types = event.attachment_types)
            next unless types.include?(type)
          end
          processor_type = event.processor_type || default_processor_type
          processor_class = Processor.const_get(processor_type.to_s.camelize)
          processor = processor_class.new(self, stream.path)
          styles = reflection.styles
          names = options[:styles] || event.styles and
            styles = reflection.styles.slice(*names)
          processor.process(styles, options, &event.callback)
        end
        record.errors.empty?
      end

      #
      # Like #process, but raise ActiveRecord::RecordInvalid if there
      # are any errors.
      #
      def process!(event_name, options={}, &block)
        process(event_name, options, &block) or
          raise ActiveRecord::RecordInvalid, record
      end

      #
      # Return the path on the file system where the given style's
      # image is to be stored.
      #
      def path(style_name = reflection.default_style)
        interpolate_path(style_name)
      end

      #
      # Return the URL where the given style's image is to be found.
      #
      def url(style_name = reflection.default_style)
        interpolate_url(style_name)
      end

      #
      # Return the size of the attached file.
      #
      def file_size
        stream.size
      end

      #
      # Return the original file name of the attached file.
      #
      def file_name
        @file_name ||= stream.file_name
      end

      #
      # Return the content type of the data.
      #
      def content_type
        @content_type ||= stream.content_type
      end

      #
      # Called when the attachment is saved.
      #
      def save
        return if saved?
        self.saved = true
        original_path = interpolate_path(:original)
        stream.write_to(original_path)
      end

      #
      # Called when the attachment is destroyed, or just before
      # another attachment is saved in its place.
      #
      def destroy
        delete_files_and_empty_parent_directories
      end

      #
      # Set any attributes that the attachment is configured to store.
      #
      storable_attribute :file_name
      storable_attribute :file_size
      storable_attribute :content_type

      #
      # Ensure the file examination has been run, and return the
      # result.
      #
      def examine
        if @examination_result.nil?
          @examination_result = run_examination
        else
          @examination_result
        end
      end

      def unload
        super
        @examination_result = nil
      end

      protected  # ---------------------------------------------------

      #
      # Return the default processor class to use for this attachment.
      #
      def default_processor_type
        :base
      end

      #
      # Examine the stream.
      #
      # Return true if the stream looks like a valid instance of this
      # attachment type, false otherwise.
      #
      def run_examination
        true
      end

      #
      # Return the value of the given attribute from an instance
      # variable set during file examination.
      #
      # If not set, runs a file examination first.
      #
      def from_examination(name)
        ivar = :"@#{name}"
        value = instance_variable_get(ivar) and
          return value
        examine
        instance_variable_get(ivar)
      end

      private  # -------------------------------------------------------

      #
      # Remove the files for this attachment, along with any parent
      # directories.
      #
      def delete_files_and_empty_parent_directories
        style_names = reflection.styles.map{|style| style.name} << :original
        # If the attachment was set to nil, we need the original value
        # to work out what to delete.
        if column_name = reflection.column_name_for_stored_attribute(:file_name)
          interpolation_params = {:basename => record.send("#{column_name}_was")}
        else
          interpolation_params = {}
        end
        style_names.each do |style_name|
          path = interpolate_path(style_name, interpolation_params) or
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
