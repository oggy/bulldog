module Bulldog
  module Processor
    class Base
      def initialize(input_file, styles)
        @input_file = input_file
        @styles = styles
        @record = nil
        @name = nil
      end

      #
      # The name of the original file.
      #
      attr_reader :input_file

      def output_file(style_name)
        # TODO: Make Processor take an Attachment.  This then just
        # becomes attachment.path(style_name).
        path = @styles[style_name][:path] and
          return path
        attachment = record.send(:attachment_for, name)
        template = attachment.reflection.path_template
        Interpolation.interpolate(template, record, name, @styles[style_name])
      end

      #
      # The record being processed.
      #
      attr_reader :record

      #
      # The name of the attachment being processed.
      #
      attr_reader :name

      #
      # Return the value of the attachment.
      #
      def value
        record.send(name).value
      end

      #
      # Return the styles matching the given options.
      #
      # If an :if option is present, don't include any styles not
      # named.  If an :unless options is present, omit these styles.
      #
      def styles(options={})
        only = Array(options[:only])
        except = Array(options[:except])
        styles = @styles
        styles = only.present? ? @styles.select{|s| only.include?(s.name)} : styles
        except.present? ? styles.reject{|s| except.include?(s.name)} : styles
      end

      #
      # Run the given block in the context of this processor.
      #
      # Subclasses may override this to do any additional pre- or
      # post- processing.  e.g., see photo.rb.
      #
      def process(record, name, *args, &block)
        @record = record
        @name = name
        instance_exec(*args, &block) if block
      end

      protected  # ---------------------------------------------------

      #
      # Return the path of the first occurrence of +basename+ in the
      # current PATH, or nil if the file cannot be found.
      #
      def self.find_in_path(basename)
        ENV['PATH'].split(/:+/).each do |dirname|
          path = File.join(dirname, basename)
          if File.file?(path) && File.executable?(path)
            return path
          end
        end
        nil
      end

      def log(level, message)
        logger = Bulldog.logger
        logger.send(level, message) unless logger.nil?
      end

      def run_command(*command)
        log :info, "Running: #{command.map(&:inspect).join(' ')}"
        # Call #system on Kernel so mocha can detect it...
        Kernel.system(*command)
      end

      def command_output(*command)
        log :info, "Running: #{command.map(&:inspect).join(' ')}"
        string = command.map{|arg| shell_escape(arg)}.join(' ')
        # Call #` on Kernel so mocha can detect it...
        Kernel.send(:'`', string)
      end

      def shell_escape(str)
        if RUBY_VERSION >= '1.9'
          Shellwords.shellescape(str)
        else
          # Taken from ruby 1.9.

          # An empty argument will be skipped, so return empty quotes.
          return "''" if str.empty?

          str = str.dup

          # Process as a single byte sequence because not all shell
          # implementations are multibyte aware.
          str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/n, "\\\\\\1")

          # A LF cannot be escaped with a backslash because a backslash + LF
          # combo is regarded as line continuation and simply ignored.
          str.gsub!(/\n/, "'\n'")

          return str
        end
      end
    end
  end
end
