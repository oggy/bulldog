module Bulldog
  module Processor
    class Ffmpeg < Base
      class << self
        attr_accessor :ffmpeg_command
      end

      self.ffmpeg_command = find_in_path('ffmpeg')

      def process(*args)
        initialize_style_lists
        super
        run_ffmpeg
      end

      private  # -----------------------------------------------------

      def initialize_style_lists
        @style_lists = {}
        styles.each do |style|
          @style_lists[style.name] = StyleData.new([], [])
        end
      end

      def run_ffmpeg
        @style_lists.each do |name, data|
          command = [self.class.ffmpeg_command]
          command.concat data.infile_options
          command << '-i' << input_file
          command.concat data.outfile_options
          command << output_file(name)
          run_command(*command)
        end
      end
    end
  end

  StyleData = Struct.new(:infile_options, :outfile_options)
end
