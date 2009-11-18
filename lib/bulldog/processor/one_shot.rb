module Bulldog
  module Processor
    class OneShot < Base
      def initialize(*args)
        super
        @styles = StyleSet.new
      end

      def process(*args, &block)
        @style = nil
        process_style(&block)
      end

      def output_file(style_name)
        nil
      end
    end
  end
end
