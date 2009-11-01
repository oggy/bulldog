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

      def process(*args)
        return if styles.empty?
        reset
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
      def dimensions(options={}, &block)
        operate(options){['-format', '%w %h', '-identify']}
        after_convert(options) do |styles, output|
          width, height = output.gets.split.map(&:to_i)
          block.call(styles, width, height)
        end
      end

      private  # -----------------------------------------------------

      def run_after_convert_callbacks(output)
        io = StringIO.new(output)
        @after_convert_callbacks.each do |callback|
          callback.call(io)
        end
      end

      # Image operations  --------------------------------------------

      def resize(options={})
        operate(options){|style| ['-resize', style[:size]]}
      end

      def auto_orient(options={})
        operate(options){|style| '-auto-orient'}
      end

      def strip(options={})
        operate(options){|style| '-strip'}
      end

      def flip(options={})
        operate(options){|style| '-flip'}
      end

      def flop(options={})
        operate(options){|style| '-flop'}
      end

      def thumbnail(options={})
        operate(options){|style| [['-resize', "#{style[:size]}^"], ['-gravity', 'Center'], ['-crop', style[:size]]]}
      end

      private  # -----------------------------------------------------

      def reset
        @tree = ArgumentTree.new(styles)
        @after_convert_callbacks = []
      end

      def operate(options={}, &block)
        styles(options).each do |style|
          arguments = yield(style)
          @tree.add(style, arguments)
        end
      end

      def after_convert(options={}, &callback)
        styles(options).each do |style|
          @tree.add(style, [callback])
        end
      end

      def run_convert
        add_image_setting_arguments
        add_output_arguments
        output = run_convert_command
        run_after_convert_callbacks(output)
      end

      def add_output_arguments
        styles.each do |style|
          @tree.add(style, ['-write', output_file(style.name)])
        end
      end

      def add_image_setting_arguments
        styles.each do |style|
          @tree.add(style, ['-quality', style[:quality].to_s]) if style[:quality]
          @tree.add(style, ['-colorspace', style[:colorspace]]) if style[:colorspace]
        end
      end

      def run_convert_command
        words = []
        construct_convert_command(words, @tree.root, false)
        command = [self.class.convert_command, input_file, *words].flatten
        command[-2] == '-write' or
          raise '[BULLDOG BUG]: expected second last word of convert command to be -write'
        command.delete_at(-2)
        command_output(*command)
      end

      def construct_convert_command(words, node, clone_needed)
        if clone_needed
          words << '(' << '+clone'
          construct_convert_command(words, node, false)
          words << '+delete' << ')'
        else
          procs, strings = node.arguments.partition{|a| a.is_a?(Proc)}
          words.concat(strings)
          callbacks = procs.map{|proc| lambda{|output| proc.call(node.styles, output)}}
          @after_convert_callbacks.concat(callbacks)
          if node.children.empty?
            # TODO: Support multiple styles here. (Not likely you'd
            # want to generate the same file twice, though.)
            #words << '-write' << output_file(node.styles.first.name)
          else
            children = node.children.dup
            last_child = children.pop
            children.each do |child|
              construct_convert_command(words, child, true)
            end
            construct_convert_command(words, last_child, false)
          end
        end
      end
    end
  end
end
