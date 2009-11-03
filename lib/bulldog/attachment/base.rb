module Bulldog
  module Attachment
    class Base < Maybe
      def initialize(record, name, stream)
        @record = record
        @name = name
        @stream = stream
        @value = stream && stream.target
      end

      #
      # Run the processors for the named event.
      #
      def process(event_name, *args)
        reflection.events[event_name].each do |event|
          next unless event.attachment_types.any? do |type|
            self.is_a?( Attachment.class_from_type(type) )
          end
          processor_type = event.processor_type || default_processor_type
          processor_class = Processor.const_get(processor_type.to_s.camelize)
          processor = processor_class.new(self, styles_for_event(event), stream.path)
          processor.process(*args, &event.callback)
        end
      end

      def path(style_name = reflection.default_style)
        interpolate_path(style_name)
      end

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

      protected  # ---------------------------------------------------

      #
      # Return the default processor class to use for this attachment.
      #
      def default_processor_type
        :base
      end

      private  # -------------------------------------------------------

      def styles_for_event(event)
        if event.styles
          styles = reflection.styles.slice(*event.styles)
        else
          styles = reflection.styles
        end
      end
    end
  end
end
