module Bulldog
  #
  # Gives IO, Tempfile, and UnopenedFile a common interface.
  #
  # In particular, this takes care of writing it to a file so external
  # programs may be called on it, while keeping the number of file
  # writes to a minimum.
  #
  module Stream
    def self.new(object)
      klass =
        case object
        when Tempfile
          ForTempfile
        when File
          ForFile
        when UnopenedFile
          ForUnopenedFile
        when StringIO
          ForStringIO
        when IO
          ForIO
        end
      klass.new(object)
    end

    class Base
      def initialize(target)
        @target = target
      end

      #
      # The underlying object.
      #
      attr_reader :target

      #
      # Return the path of a file where the content can be found.
      #
      def path
        @target.path
      end

      #
      # Return the size of the content.
      #
      def size
        File.size(path)
      end

      #
      # Return the mime-type of the content.
      #
      def content_type
        @content_type ||= `file --brief --mime #{path}`.strip
      end

      #
      # Write the content to the given path.
      #
      def write_to(path)
        FileUtils.mkdir_p File.dirname(path)
        src, dst = self.path, path
        FileUtils.cp src, dst unless src == dst
      end
    end

    class ForTempfile < Base
      def initialize(target)
        super
        @path = target.path or
          raise ArgumentError, "Tempfile is closed - cannot retrieve information"
      end

      def path
        @target.flush unless @target.closed?
        super
      end

      def size
        # Tempfile#size returns nil when closed.
        @target.flush unless @target.closed?
        File.size(@target.path)
      end
    end

    class ForFile < Base
      def path
        @target.flush unless @target.closed? rescue IOError  # not open for writing
        super
      end
    end

    class ForUnopenedFile < Base
    end

    class ForIO < Base
      def path
        return @path if @path
        Tempfile.open('bulldog') do |file|
          write_to_io(file)
          @path = file.path

          # Don't let the tempfile be GC'd until the stream is, as the
          # tempfile's finalizer deletes the file.
          @tempfile = file
        end
        @path
      end

      def write_to(path)
        if @path
          super
        else
          open(path, 'w') do |file|
            write_to_io(file)
            @path = file.path
          end
        end
      end

      private  # -----------------------------------------------------

      BLOCK_SIZE = 64*1024
      def write_to_io(io)
        target.rewind rescue nil  # not rewindable
        buffer = ""
        while target.read(BLOCK_SIZE, buffer)
          io.write(buffer)
        end
      end
    end

    class ForStringIO < ForIO
      def size
        @target.size
      end
    end
  end
end
