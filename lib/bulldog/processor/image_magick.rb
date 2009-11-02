require 'stringio'

module Bulldog
  module Processor
    class ImageMagick < Base
      class << self
        attr_accessor :convert_command
        attr_accessor :identify_command
      end

      self.convert_command = find_in_path('convert')
      self.identify_command = find_in_path('identify')

      def initialize(*args)
        super
        @tree = ArgumentTree.new(styles)
      end

      def process(*args, &block)
        return if styles.empty?
        super
        run_convert
      end

      # Input image attributes  --------------------------------------

      #
      # Yield the dimensions of the generated file at this point in
      # the pipeline.
      #
      # The block is called when `convert' is run after the processor
      # block is evaluated for all styles.  If you just need the
      # dimensions of the input file, see Attribute::Photo#dimensions.
      #
      def dimensions(&block)
        operate '-format', '%w %h'
        operate '-identify' do |styles, output|
          width, height = output.gets.split.map(&:to_i)
          block.call(styles, width, height)
        end
      end

      private  # -----------------------------------------------------

      # Image operations  --------------------------------------------

      def resize
        operate '-resize', style[:size]
      end

      def auto_orient
        operate '-auto-orient'
      end

      def strip
        operate '-strip'
      end

      def flip
        operate '-flip'
      end

      def flop
        operate '-flop'
      end

      def thumbnail
        operate '-resize', "#{style[:size]}^"
        operate '-gravity', 'Center'
        operate '-crop', style[:size]
      end

      private  # -----------------------------------------------------

      def operate(*arguments, &block)
        @tree.add(style, arguments, &block)
      end

      def run_convert
        add_final_style_arguments
        output = run_convert_command
        run_convert_callbacks(output)
      end

      def add_final_style_arguments
        styles.each do |style|
          @tree.add(style, ['-quality', style[:quality].to_s]) if style[:quality]
          @tree.add(style, ['-colorspace', style[:colorspace]]) if style[:colorspace]
          path = output_file(style.name)
          FileUtils.mkdir_p(File.dirname(path))
          @tree.output(style, path)
        end
      end

      def run_convert_command
        command = [self.class.convert_command, input_file, *@tree.arguments].flatten
        command_output(*command)
      end

      def run_convert_callbacks(output)
        io = StringIO.new(output)
        @tree.each_callback do |styles, callback|
          callback.call(styles, io)
        end
      end
    end
  end
end
