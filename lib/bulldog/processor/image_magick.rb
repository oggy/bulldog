require 'stringio'

module Bulldog
  module Processor
    class ImageMagick < Base
      class << self
        attr_accessor :convert_command
        attr_accessor :identify_command
      end

      self.convert_command = 'convert'
      self.identify_command = 'identify'

      def initialize(*args)
        super
        @tree = ArgumentTree.new(styles)
      end

      def process
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

      def rotate(angle)
        unless angle.to_i.zero?
          operate '-rotate', angle.to_s
        end
      end

      def crop(params)
        operate '-crop', geometry(params[:size], params[:origin])
        operate '+repage'
      end

      def thumbnail
        if style[:filled]
          operate '-resize', "#{style[:size]}^"
          operate '-gravity', 'Center'
          operate '-crop', "#{style[:size]}+0+0"
          operate '+repage'
        else
          operate '-resize', "#{style[:size]}"
        end
      end

      private  # -----------------------------------------------------

      def geometry(size, origin=nil)
        size = Vector2.new(size)
        geometry = '%dx%d' % [size.x, size.y]
        if origin
          origin = Vector2.new(origin)
          geometry << ('%+d%+d' % [origin.x, origin.y])
        end
        geometry
      end

      def operate(*arguments, &block)
        @tree.add(style, arguments, &block)
      end

      def run_convert
        add_final_style_arguments
        output = run_convert_command and
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
        command = [self.class.convert_command, "#{input_file}[0]", *@tree.arguments].flatten
        output = Bulldog.run(*command) or
          record.errors.add name, "convert failed (status #$?)"
        output
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
