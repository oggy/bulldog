module Bulldog
  module Processor
    class Base
      def initialize(input_file, styles)
        @input_file = input_file
        @styles = styles
      end

      attr_reader :input_file

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
      def process(*args, &block)
        instance_exec(*args, &block)
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
    end
  end
end
