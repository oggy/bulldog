module Bulldog
  #
  # Gives IO, StringIO, Tempfile, and SavedFile a common interface.
  #
  # In particular, this takes care of writing it to a file so external
  # programs may be called on it, while keeping the number of file
  # writes to a minimum.
  #
  module Stream
    def self.new(object)
      klass =
        case object
        when ::Tempfile
          ForTempfile
        when File
          ForFile
        when SavedFile
          ForSavedFile
        when MissingFile
          ForMissingFile
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
      # Return true if this stream represents a missing file.
      #
      def missing?
        false
      end

      #
      # Return the original file name of the underlying object.  This
      # is the basename of the file as the user uploaded it (for an
      # uploaded file), or the file on the filesystem (for a File
      # object).  For other IO objects, return nil.
      #
      def file_name
        if @target.respond_to?(:original_path)
          @target.original_path
        else
          nil
        end
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
        src, dst = self.path, path
        unless src == dst
          FileUtils.mkdir_p File.dirname(path)
          FileUtils.cp src, dst
        end
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

      def file_name
        super || File.basename(@target.path)
      end
    end

    class ForSavedFile < Base
      delegate :file_name, :to => :target
    end

    class ForMissingFile < Base
      def missing?
        true
      end

      delegate :file_name, :to => :target

      def content_type
        @target.content_type || super
      end
    end

    class ForIO < Base
      def path
        return @path if @path
        # Keep extension if it's available.  Some commands may use the
        # file extension of the input file, for example.
        tempfile_name = 'bulldog'
        if @target.respond_to?(:original_path) && @target.original_path
          tempfile_name = [tempfile_name, File.extname(@target.original_path)]
        end
        Tempfile.open(tempfile_name) do |file|
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
      delegate :size, :to => :target
    end
  end
end
