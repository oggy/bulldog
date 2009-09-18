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
        initialize_lists
        super
        run_convert
      end

      # Input image attributes  --------------------------------------

      def dimensions
        output = run_identify('-format', '%w %h', "#{input_file}[0]")
        output.split.map(&:to_i)
      end

      # Image operations  --------------------------------------------

      def resize(options={})
        styles(options).each do |style|
          @style_lists[style.name] << ['-resize', style[:size]]
        end
        convert(options)
      end

      def auto_orient(options={})
        styles(options).each do |style|
          @style_lists[style.name] << '-auto-orient'
        end
        convert(options)
      end

      #
      # Create thumbnails.
      #
      # For the styles given with a :crop option, this shrinks the
      # image until either the width or height fits, and then crops
      # off the edges.  For other styles, this is the same as #resize.
      #
      def thumbnail(options={})
        styles(options).each do |style|
          @style_lists[style.name] <<
            ['-resize', "#{style[:size]}^"] <<
            ['-gravity', 'Center'] <<
            ['-crop', style[:size]]
        end
        convert(options)
      end

      def convert(options={})
        styles(options).each do |style|
          @output_flags[style.name] = true
        end
      end

      private  # -----------------------------------------------------

      def initialize_lists
        @style_lists = ActiveSupport::OrderedHash.new
        @output_flags = {}
        styles.each do |style|
          @style_lists[style.name] = []
          @output_flags[style.name] = false
        end
      end

      attr_reader :style_lists, :output_flags

      def run_identify(*args)
        command_output self.class.identify_command, *args
      end

      def run_convert
        prefix = extract_common_prefix
        remove_nonoutput_lists
        unless style_lists.empty?
          add_stack_manipulations
          run_convert_command(prefix)
        end
      end

      def remove_nonoutput_lists
        style_lists.delete_if do |name, list|
          !output_flags[name]
        end
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
        output_files = output_styles.map{|style| output_file(style.name)}
        lists        = output_styles.map{|style| style_lists[style.name]}

        last_output_file = output_files.pop
        last_list = lists.pop

        lists.zip(output_files).each do |list, output_file|
          list.unshift('(', '+clone')
          list.push('-write', output_file, '+delete', ')')
        end
        last_list << last_output_file
      end

      def run_convert_command(prefix)
        operations = output_styles.map{|s| style_lists[s.name]}
        command = [self.class.convert_command, input_file, prefix, operations].flatten
        run_command *command
      end

      def output_styles
        @output_styles ||= styles.select{|style| @output_flags[style.name]}
      end
    end
  end
end