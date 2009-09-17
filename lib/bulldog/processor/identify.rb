module Bulldog
  module Processor
    class Identify < Base
      class << self
        attr_accessor :command
      end

      self.command = find_in_path('identify')

      def dimensions
        run('-format', '%w %h', "#{input_file}[0]").split.map(&:to_i)
      end

      private  # -----------------------------------------------------

      def run(*args)
        command_output self.class.command, *args
      end
    end
  end
end
