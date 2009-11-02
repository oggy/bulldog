module Bulldog
  module Attachment
    class Base
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
        calculate_path(style_name)
      end

      def url(style_name = reflection.default_style)
        calculate_url(style_name)
      end

      #
      # Return the size of the attached file.
      #
      delegate :size, :to => 'stream'

      #
      # Return the content type of the data.
      #
      delegate :content_type, :to => 'stream'

      def save
        return if saved?
        @saved = true
        original_path = calculate_path(:original)
        stream.write_to(original_path)
      end

      def destroy
        delete_files_and_empty_parent_directories
      end

      def reflection
        @reflection ||= record.class.attachment_reflections[name]
      end

      #
      # Set any attributes that the attachment is configured to store.
      #
      def set_stored_attributes
        if value.is_a?(File)
          set_stored_attribute(:file_name){File.basename(value.path)}
          set_stored_attribute(:file_size){File.size(value)}
        else
          set_stored_attribute(:file_name){value.original_path}
          set_stored_attribute(:file_size){value.size}
        end

        set_stored_attribute(:content_type){content_type}
        set_stored_attribute(:updated_at){Time.now}
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
      # Set the named attribute in the record to the value yielded by
      # the block.  The block is not called unless the attribute is to
      # be stored.
      #
      def set_stored_attribute(name)
        if (column_name = reflection.stored_attributes[name])
          record.send("#{column_name}=", yield)
        end
      end

      #
      # Return the default processor class to use for this attachment.
      #
      def default_processor_type
        :base
      end

      private  # -------------------------------------------------------

      def calculate_path(style_name)
        template = reflection.path_template
        style = reflection.styles[style_name]
        Interpolation.interpolate(template, record, name, style)
      end

      def calculate_url(style_name)
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

      def styles_for_event(event)
        if event.styles
          styles = reflection.styles.slice(*event.styles)
        else
          styles = reflection.styles
        end
      end

      def delete_files_and_empty_parent_directories
        style_names = reflection.styles.map{|style| style.name} << :original
        style_names.each do |style_name|
          path = calculate_path(style_name) or
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
