module FastAttachments
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

      #
      # Declare that this Processor class processes the given type.
      #
      def self.processes(type)
        Processor.register(type, self)
      end
    end
  end
end
