module FastAttachments
  class AttachmentAttribute
    def initialize(klass, name_with_optional_type, &block)
      parse_arguments(klass, name_with_optional_type)
      configure(&block)
      define_accessors
    end

    attr_accessor :class, :name, :type, :styles, :events, :file_attributes

    def process(event, record, *args)
      events[event].each do |callback|
        with_input_file_name(record) do |file_name|
          processor = Processor.class_for(type).new(file_name, styles)
          processor.process(record, *args, &callback)
        end
      end
    end

    def set_value(record, value)
      @record
    end

    def set_file_attributes(record, io)
      if io
        set_file_attribute(record, :file_name){io.original_path}
        set_file_attribute(record, :content_type){io.content_type}
        set_file_attribute(record, :file_size){io.is_a?(File) ? File.size(io) : io.size}
        set_file_attribute(record, :updated_at){Time.now}
      else
        [:file_name, :content_type, :file_size, :updated_at].each do |name|
          set_file_attribute(record, name){nil}
        end
      end
    end

    def set_file_attribute(record, name, &block)
      if (column_name = file_attributes[name])
        record.send("#{column_name}=", yield)
      end
    end

    private  # -------------------------------------------------------

    def parse_arguments(klass, name_with_optional_type)
      @class = klass
      if name_with_optional_type.is_a?(Hash)
        name_with_optional_type.size == 1 or
          raise ArgumentError, "hash argument must have exactly 1 key/value"
        @name, @type = *name_with_optional_type.to_a.first
      else
        @name, @type = name_with_optional_type, nil
      end
    end

    def configure(&block)
      configuration = Configuration.new(self.class, name, type)
      configuration.instance_eval(&block) if block
      [:styles, :events, :file_attributes].each do |field|
        send("#{field}=", configuration.send(field))
      end
      self.class.attachment_attributes[name] = self
    end

    def define_accessors
      self.class.module_eval <<-EOS, __FILE__, __LINE__
        def #{@name}
          read_attribute(:#{@name})
        end

        def #{@name}=(value)
          process_attachment(:#{@name}, :before_assignment, value)
          write_attribute(:#{@name}, value)
          attachment_attributes[:#{@name}].set_file_attributes(self, value)
          process_attachment(:#{@name}, :after_assignment, value)
        end

        def #{@name}?
          !!#{@name}
        end
      EOS
    end

    #
    # Yield the name of the file this attachment is stored in.  The
    # file will be kept for the duration of the block.
    #
    # If the attribute is nil, the block is not yielded.
    #
    def with_input_file_name(record)
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
  end
end
