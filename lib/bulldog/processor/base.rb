module Bulldog
  module Processor
    class Base
      def initialize(attachment, styles, input_file)
        @attachment = attachment
        @styles = styles
        @input_file = input_file
      end

      #
      # The attachment object being processed.
      #
      attr_reader :attachment

      #
      # The styles to run this processor for.
      #
      attr_reader :styles

      #
      # The record being processed.
      #
      def record
        attachment.record
      end

      #
      # The name of the attachment being processed.
      #
      def name
        attachment.name
      end

      #
      # The name of the original file.
      #
      attr_reader :input_file

      #
      # The name of the output file for the given style.
      #
      def output_file(style_name)
        overrides = {}
        if (format = styles[style_name][:format])
          overrides[:extension] = format
        end
        attachment.interpolate_path(style_name, overrides)
      end

      #
      # Return the value of the attachment.
      #
      def value
        record.send(name).value
      end

      #
      # Run the given block in the context of this processor, once for
      # each style.
      #
      # #style will be set to the current style each time the block is
      # called.
      #
      # Return true if any styles were processed, false otherwise.
      # Subclasses can use this to determine if any processing
      # commands need to be run.
      #
      def process(options={}, &block)
        styles = self.styles
        style_names = options[:styles] and
          styles = styles.slice(*style_names)

        return false if styles.empty?
        styles.each do |style|
          @style = style
          begin
            process_style(&block)
          ensure
            @style = nil
          end
        end
        true
      end

      #
      # The current style being processed.
      #
      attr_reader :style

      protected  # ---------------------------------------------------

      #
      # Run the given block with #style set to one of the styles to
      # process.
      #
      # This is called by #process for each output style.
      #
      def process_style(*args, &block)
        # Avoid #instance_exec if possible for ruby 1.8.
        evaluator = args.empty? ? :instance_eval : :instance_exec
        send(evaluator, *args, &block) if block
      end

      def log(level, message)
        logger = Bulldog.logger
        logger.send(level, message) unless logger.nil?
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
