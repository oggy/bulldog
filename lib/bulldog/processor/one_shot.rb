module Bulldog
  module Processor
    class OneShot < Base
      def initialize(*args)
        super
        @styles.clear
      end

      def process(*args, &block)
        @style = nil
        process_style(*args, &block)
      end

      def output_file(style_name)
        nil
      end
    end
  end
end
