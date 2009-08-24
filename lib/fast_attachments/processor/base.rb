module FastAttachments
  module Processor
    class Base
      #
      # Declare that this Processor class processes the given type.
      #
      def self.processes(type)
        Processor.process type, :with => self
      end
    end
  end
end
