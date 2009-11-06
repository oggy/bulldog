module Bulldog
  module Processor
    class Ffmpeg < Base
      class << self
        attr_accessor :ffmpeg_command
      end

      self.ffmpeg_command = find_in_path('ffmpeg')

      def initialize(*args)
        super
        @operation = nil
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
        run_default_operation
      end

      def use_threads(num_threads)
        operate '-threads', num_threads
      end

      def encode(params={})
        params = style.attributes.merge(params)
        @operation = :encode
        add_video_options(params[:video])
        add_audio_options(params[:audio])
        style_option '-s', params[:size]
        style_option '-ac', params[:num_channels]
        operate '-deinterlace' if params[:deinterlaced]
        style_option '-pix_fmt', params[:pixel_format]
        style_option '-b_strategy', params[:b_strategy]
        style_option '-bufsize', params[:buffer_size]
      end

      private  # -----------------------------------------------------

      def operate(*args)
        @arguments[style].concat args.map(&:to_s)
      end

      def run_default_operation
        encode if @operation.nil?
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
          when 'mono'
            operate '-ac', '1'
          when 'stereo'
            operate '-ac', '2'
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
          command << '-y' << output_file(style.name)
          run_command(*command)
        end
      end
    end
  end
end
