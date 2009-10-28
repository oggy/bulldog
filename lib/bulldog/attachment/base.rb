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
      # Run the processors for the given event.
      #
      def process(event, *args)
        reflection.events[event].each do |processor_type, callback|
          with_input_file_name do |file_name|
            processor_type ||= default_processor_type
            processor_class = Processor.const_get(processor_type.to_s.camelize)
            processor = processor_class.new(file_name, reflection.styles)
            processor.process(record, name, *args, &callback)
          end
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
        saved = true
        original_path = calculate_path(:original)
        case (file = value)
        when File, Tempfile, StringIO
          write_stream(file, original_path)
        when UnopenedFile
          unless file.path == original_path
            FileUtils.cp(file.path, original_path)
          end
        when nil
          delete_files_and_empty_parent_directories
        else
          raise "unexpected value for file: #{file.inspect}"
        end
      end

      def destroy
        delete_files_and_empty_parent_directories
      end

      def reflection
        @reflection ||= record.class.attachment_reflections[name]
      end

      #
      # Set any file attributes that the attachment is configured to
      # store.
      #
      def set_file_attributes
        if value.is_a?(File)
          set_file_attribute(:file_name){File.basename(value.path)}
          set_file_attribute(:file_size){File.size(value)}
        else
          set_file_attribute(:file_name){value.original_path}
          set_file_attribute(:file_size){value.size}
        end

        set_file_attribute(:content_type){content_type}
        set_file_attribute(:updated_at){Time.now}
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

      #
      # Yield the name of the file this attachment is stored in.  The
      # file will be kept for the duration of the block.
      #
      def with_input_file_name
        case value
        when UnopenedFile, Tempfile, File
          yield value.path
        when StringIO
          # not on the filesystem - dump it
          file_name = nil
          begin
            with_string_io_dumped_to_file(value) do |file_name|
              yield file_name
            end
          end
        else
          raise "unexpected value for attachment `#{name}': #{value.inspect}"
        end
      end

      def with_string_io_dumped_to_file(string_io)
        path = nil
        Tempfile.open(string_io.original_filename) do |tempfile|
          path = tempfile.path
          copy_stream(string_io, tempfile)
        end
        yield path
      ensure
        File.unlink(path)
      end

      def copy_stream(src, dst, block_size=8192)
        src.rewind
        buffer = ""
        while src.read(block_size, buffer)
          dst.write(buffer)
        end
        dst.rewind
        dst
      end

      def write_stream(io, path, block_size=8192)
        FileUtils.mkdir_p(File.dirname(path))
        open(path, 'w') do |file|
          copy_stream(io, file, block_size)
        end
      end
    end
  end
end
