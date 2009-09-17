module Bulldog
  module Processor
    class Convert < Base
      class << self
        attr_accessor :command
      end

      self.command = find_in_path('convert')

      def process(*args)
        initialize_style_lists
        super
        run_convert
      end

      def resize(options={})
        styles(options).each do |style|
          @style_lists[style.name] << ['-resize', style[:size]]
        end
      end

      def auto_orient(options={})
        styles(options).each do |style|
          @style_lists[style.name] << '-auto-orient'
        end
      end

      #
      # Create thumbnails.
      #
      # For the styles given with a :crop option, this shrinks the
      # image until either the width or height fit, and then crops off
      # the edges.  For other styles, this is the same as #resize.
      #
      def thumbnail(options={})
        styles(options).each do |style|
          @style_lists[style.name] <<
            ['-resize', "#{style[:size]}^"] <<
            ['-gravity', 'Center'] <<
            ['-crop', style[:size]]
        end
      end

      private  # -----------------------------------------------------

      def initialize_style_lists
        @style_lists = {}
        styles.each do |style|
          @style_lists[style.name] = []
        end
      end

      attr_reader :style_lists

      def run_convert
        prefix = extract_common_prefix
        add_stack_manipulations
        run_command *make_command(prefix)
      end

      def extract_common_prefix
        return [] if styles.empty?
        length = 0
        first, *rest = style_lists.values
        first.zip(*rest) do |elements|
          if elements.uniq.size == 1
            length += 1
          else
            break
          end
        end
        rest.each{|list| list[0, length] = []}
        first.slice!(0, length)
      end

      def add_stack_manipulations
        output_files = styles.map{|style| output_file(style.name)}
        lists        = styles.map{|style| style_lists[style.name]}

        last_output_file = output_files.pop
        last_list = lists.pop

        lists.zip(output_files).each do |list, output_file|
          list.unshift('(', '+clone')
          list.push('-write', output_file, '+delete', ')')
        end
        last_list << last_output_file
      end

      def make_command(prefix)
        operations = styles.map{|s| style_lists[s.name]}
        [self.class.command, input_file, prefix, operations].flatten
      end
    end
  end
end
