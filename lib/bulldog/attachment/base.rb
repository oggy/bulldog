module Bulldog
  module Attachment
    class Base < Maybe
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

      protected  # ---------------------------------------------------

      #
      # Return the default processor class to use for this attachment.
      #
      def default_processor_type
        :base
      end

      #
      # Return the dimensions, as an array [width, height], that
      # result from resizing +original_dimensions+ to
      # +target_dimensions+.  If fill is true, assume the final image
      # will fill the target box.
      #
      def resized_dimensions(original_dimensions, target_dimensions, fill)
        if fill
          target_dimensions
        else
          original_aspect_ratio = original_dimensions[0].to_f / original_dimensions[1]
          target_aspect_ratio = target_dimensions[0].to_f / target_dimensions[1]
          if original_aspect_ratio > target_aspect_ratio
            width = target_dimensions[0]
            height = (width / original_aspect_ratio).round
          else
            height = target_dimensions[1]
            width = (height * original_aspect_ratio).round
          end
          [width, height]
        end
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
