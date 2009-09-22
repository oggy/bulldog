require 'stringio'

module Bulldog
  module Processor
    class Image < Base
      class << self
        attr_accessor :convert_command
        attr_accessor :identify_command
      end

      self.convert_command = find_in_path('convert')
      self.identify_command = find_in_path('identify')

      def process(*args)
        reset
        super
        run_convert
      end

      # Input image attributes  --------------------------------------

      def dimensions(options={}, &block)
        if block
          operate(options){['-format', '%w %h', '-identify']}
          after_convert(options) do |styles, output|
            width, height = output.gets.split.map(&:to_i)
            block.call(styles, width, height)
          end
          convert(options)
        else
          output = run_identify('-format', '%w %h', "#{input_file}[0]")
          output.split.map(&:to_i)
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

      def convert(options={})
        styles(options).each do |style|
          @output_flags[style] = true
        end
      end

      private  # -----------------------------------------------------

      def reset
        @tree = ArgumentTree.new(styles)
        @output_flags = {}
        styles.each do |style|
          @output_flags[style] = false
        end
        @after_convert_callbacks = []
      end

      attr_reader :output_flags

      def operate(options={}, &block)
        arguments = ActiveSupport::OrderedHash.new
        styles(options).each do |style|
          arguments[style] = yield(style)
        end
        @tree.add(arguments)
        convert(options)
      end

      def after_convert(options={}, &callback)
        @tree.add_for_styles(styles(options), [callback])
      end

      def run_identify(*args)
        command_output self.class.identify_command, *args
      end

      def run_convert
        @output_flags.any?{|style, flag| flag} or
          return
        remove_nodes_for_non_output_styles
        add_image_setting_arguments
        add_output_arguments
        output = run_convert_command
        run_after_convert_callbacks(output)
      end

      def remove_nodes_for_non_output_styles
        @output_flags.each do |style, flag|
          @tree.remove_style(style) if !flag
        end
      end

      def add_output_arguments
        arguments = ActiveSupport::OrderedHash.new
        @output_flags.each do |style, flag|
          arguments[style] = ['-write', output_file(style.name)]
        end
        @tree.add(arguments)
      end

      def add_image_setting_arguments
        arguments = ActiveSupport::OrderedHash.new
        styles.each do |style|
          @output_flags[style] or
            next
          list = []
          list << ['-quality', style[:quality].to_s] if style[:quality]
          list << ['-colorspace', style[:colorspace]] if style[:colorspace]
          arguments[style] = list
        end
        @tree.add(arguments)
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
