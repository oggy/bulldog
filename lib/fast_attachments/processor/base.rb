module FastAttachments
  module Processor
    class Base
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
