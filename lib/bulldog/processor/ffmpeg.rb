module Bulldog
  module Processor
    class Ffmpeg < Base
      class << self
        attr_accessor :ffmpeg_command
      end

      self.ffmpeg_command = find_in_path('ffmpeg')

      def initialize(*args)
        super
        @arguments = {}
        styles.each{|s| @arguments[s] = []}
      end

      def process(*args)
        return if styles.empty?
        super
        run_ffmpeg
      end

      def process_style(*args)
        super
        add_style_options
      end

      def use_threads(num_threads)
        operate '-threads', num_threads
      end

      private  # -----------------------------------------------------

      def operate(*args)
        @arguments[style].concat args.map(&:to_s)
      end

      def add_style_options
        add_video_options(style[:video])
        add_audio_options(style[:audio])
        style_option '-s', style[:size]
        style_option '-ac', style[:num_channels]
        operate '-deinterlace' if style[:deinterlaced]
        style_option '-pix_fmt', style[:pixel_format]
        style_option '-b_strategy', style[:b_strategy]
        style_option '-bufsize', style[:buffer_size]
      end

      def add_video_options(spec)
        return if spec.blank?
        spec.split.each do |word|
          case word
          when /fps\z/i
            operate '-r', $`
          when /bps\z/i
            operate '-b', $`
          when /\A(\d+)x(\d+)\z/i
            operate '-s', "#$1x#$2"
          else
            operate '-vcodec', word
          end
        end
      end

      def add_audio_options(spec)
        return if spec.blank?
        spec.split.each do |word|
          case word
          when /hz\z/i
            operate '-ar', $`
          when /bps\z/i
            operate '-ab', $`
          else
            operate '-acodec', word
          end
        end
      end

      def style_option(option, *args)
        operate(option, *args) if args.all?
      end

      def run_ffmpeg
        @arguments.each do |style, arguments|
          command = [self.class.ffmpeg_command]
          command << '-i' << input_file
          command.concat(arguments)
          command << output_file(style.name)
          run_command(*command)
        end
      end
    end
  end
end
