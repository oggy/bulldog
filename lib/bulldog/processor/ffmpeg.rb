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
        @arguments = style_list_map
        @still_frame_callbacks = style_list_map
      end

      def process(*args)
        return if styles.empty?
        super
        run_ffmpeg
        run_still_frame_callbacks
      end

      def process_style(*args)
        super
        run_default_operation
      end

      def use_threads(num_threads)
        operate '-threads', num_threads
      end

      def encode(params={})
        @operation = :encode
        params = style.attributes.merge(params)
        add_video_options(params[:video])
        add_audio_options(params[:audio])
        style_option '-s', params[:size]
        style_option '-ac', params[:num_channels]
        operate '-deinterlace' if params[:deinterlaced]
        style_option '-pix_fmt', params[:pixel_format]
        style_option '-b_strategy', params[:b_strategy]
        style_option '-bufsize', params[:buffer_size]
        preset_option '-vpre', params[:video_preset]
        preset_option '-apre', params[:audio_preset]
        preset_option '-spre', params[:subtitle_preset]
        style_option '-y', output_file(style.name)
      end

      def record_frame(params={}, &block)
        @operation = :record_frame
        params = style.attributes.merge(params)
        operate '-vframes', 1
        operate '-ss', params[:position] || attachment.duration.to_i / 2
        operate '-f', 'image2'
        operate '-vcodec', params[:codec] || default_frame_codec(params)

        if (attribute = params[:assign_to])
          basename = "recorded_frame.#{params[:format]}"
          output_path = record.send(attribute).interpolate_path(:original, :basename => basename)
          @still_frame_callbacks[style] << lambda do
            file = SavedFile.new(output_path, :file_name => basename)
            record.update_attribute(attribute, file)
          end
        else
          output_path = output_file(style.name)
        end

        operate '-y', output_path
        if block
          @still_frame_callbacks[style] << lambda{instance_exec(output_path, &block)}
        end
      end

      private  # -----------------------------------------------------

      def style_list_map
        hash = {}
        styles.each{|s| hash[s] = []}
        hash
      end

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

      def preset_option(option, value)
        Array(value).each do |preset|
          operate option, preset
        end
      end

      def default_frame_codec(params)
        case params[:format].to_s
        when /jpe?g/i
          'mjpeg'
        when /png/i
          'png'
        else
          format = params[:format]
          raise ProcessingError, "no default codec for '#{format}' - please use :codec to specify"
        end
      end

      def run_ffmpeg
        @arguments.each do |style, arguments|
          command = [self.class.ffmpeg_command]
          command << '-i' << input_file
          command.concat(arguments)
          Bulldog.run(*command)
        end
      end

      def run_still_frame_callbacks
        @still_frame_callbacks.each do |style, callbacks|
          callbacks.each{|c| c.call}
        end
      end
    end
  end
end
