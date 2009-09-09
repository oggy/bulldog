module Bulldog
  class AttachmentAttribute
    def initialize(record, name)
      @record = record
      @name = name
      @assigned = false
    end

    attr_reader :record, :name

    def process(event, *args)
      reflection.events[event].each do |callback|
        with_input_file_name do |file_name|
          processor = Processor.class_for(reflection.type).new(file_name, reflection.styles)
          processor.process(record, *args, &callback)
        end
      end
    end

    def get
      if !@assigned
        path = calculate_path(:original)
        value = File.exist?(path) ? UnopenedFile.new(path) : nil
        record.write_attribute(name, value)
        @assigned = true
      end
      record.read_attribute(name)
    end

    def set(value)
      @assigned = true
      record.write_attribute(name, value)
      set_file_attributes(value)
    end

    def basename
      if (attribute = reflection.file_attributes[:file_name])
        record.send(attribute)
      end
    end

    def query
      !!get
    end

    def path(style_name)
      return nil if !query
      calculate_path(style_name)
    end

    def save
      if @assigned
        original_path = calculate_path(:original)
        case (file = get)
        when File, StringIO
          write_stream(file, original_path)
        when UnopenedFile
          unless file.path == original_path
            FileUtils.cp(file.path, original_path)
          end
        when nil
          FileUtils.rm_f(original_path)
        else
          raise "unexpected value for file: #{file.inspect}"
        end
      end
    end

    private  # -------------------------------------------------------

    def calculate_path(style_name)
      template = reflection.path_template
      style = reflection.styles[style_name]
      Interpolation.interpolate(template, self, style)
    end

    def reflection
      @reflection ||= record.class.attachment_reflections[name]
    end

    def set_file_attributes(value)
      if value
        set_file_attribute(:file_name){value.original_path}
        set_file_attribute(:content_type){value.content_type}
        set_file_attribute(:file_size){value.is_a?(File) ? File.size(value) : value.size}
      else
        [:file_name, :content_type, :file_size].each do |name|
          set_file_attribute(name){nil}
        end
      end
      set_file_attribute(:updated_at){Time.now}
    end

    def set_file_attribute(name, &block)
      if (column_name = reflection.file_attributes[name])
        record.send("#{column_name}=", yield)
      end
    end

    #
    # Yield the name of the file this attachment is stored in.  The
    # file will be kept for the duration of the block.
    #
    # If the attribute is nil, the block is not yielded.
    #
    def with_input_file_name
      value = record.read_attribute(name)
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
      when nil
        yield nil
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
