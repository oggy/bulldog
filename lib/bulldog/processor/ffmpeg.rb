module Bulldog
  module Processor
    class Ffmpeg < Base
      class << self
        attr_accessor :ffmpeg_path
      end

      def initialize(*args)
        super
        @arguments = style_list_map
        @still_frame_callbacks = style_list_map
      end

      def process(*args)
        super or
          return
        run_still_frame_callbacks
      end

      def process_style(*args)
        @operation = nil
        super
        set_default_operation
        run_ffmpeg
      end

      def use_threads(num_threads)
        operate '-threads', num_threads
      end

      def encode(params={})
        @operation = :encode
        params = style.attributes.merge(params)
        parse_video_option(params)
        parse_audio_option(params)
        style_option '-vcodec', params[:video_codec]
        style_option '-acodec', params[:audio_codec]
        preset_option '-vpre', params[:video_preset]
        preset_option '-apre', params[:audio_preset]
        preset_option '-spre', params[:subtitle_preset]
        operate '-s', attachment.dimensions(style.name).join('x') if params[:size]
        style_option '-r', params[:frame_rate]
        style_option '-b', params[:video_bit_rate]
        style_option '-ar', params[:sampling_rate]
        style_option '-ab', params[:audio_bit_rate]
        style_option '-ac', params[:channels]
        operate '-deinterlace' if params[:deinterlaced]
        style_option '-pix_fmt', params[:pixel_format]
        style_option '-b_strategy', params[:b_strategy]
        style_option '-bufsize', params[:buffer_size]
        style_option '-coder', params[:coder]
        style_option '-v', params[:verbosity]
        style_option '-flags', params[:flags]
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

      def set_default_operation
        encode if @operation.nil?
      end

      def parse_video_option(params)
        value = params.delete(:video) or
          return
        value.split.each do |word|
          case word
          when /fps\z/i
            params[:frame_rate] = $`
          when /bps\z/i
            params[:video_bit_rate] = $`
          else
            params[:video_codec] = word
          end
        end
      end

      def parse_audio_option(params)
        value = params.delete(:audio) or
          return
        value.split.each do |word|
          case word
          when /hz\z/i
            params[:sampling_rate] = $`
          when /bps\z/i
            params[:audio_bit_rate] = $`
          when 'mono'
            params[:channels] = 1
          when 'stereo'
            params[:channels] = 2
          else
            params[:audio_codec] = word
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
        command = [self.class.ffmpeg_path]
        command << '-i' << input_file
        command.concat(@arguments[style])
        Bulldog.run(*command) or
          record.errors.add name, "convert failed (status #$?)"
      end

      def run_still_frame_callbacks
        @still_frame_callbacks.each do |style, callbacks|
          callbacks.each{|c| c.call}
        end
      end
    end
  end
end
