module Bulldog
  module Attachment
    class Video < Base
      handle :video
      include HasDimensions

      #
      # Return the duration of the named style, as an
      # ActiveSupport::Duration.
      #
      # This runs ffmpeg for, and only for, the original style.
      #
      # +style_name+ defaults to the attribute's #default_style.
      #
      def duration(style_name)
        from_examination :@original_duration
      end

      #
      # Return the video tracks of the named style, as an array of
      # VideoTrack objects.
      #
      # Each VideoTrack has:
      #
      #  * <tt>#duration</tt> - the duration of the video track.
      #  * <tt>#dimensions</tt> - the [width, height] of the video
      #    track.
      #
      def video_tracks(style_name=nil)
        style_name ||= reflection.default_style
        if style_name.equal?(:original)
          from_examination :@original_video_tracks
        else
          style = reflection.styles[style_name]
          video_tracks(:original).map do |video_track|
            dimensions = resize_dimensions(dimensions(:original), style)
            VideoTrack.new(:dimensions => dimensions)
          end
        end
      end

      #
      # Return the video tracks of the named style, as an array of
      # AudioTrack objects.
      #
      # AudioTrack objects do not yet have any useful methods.
      #
      def audio_tracks(style_name=nil)
        examine
        @original_audio_tracks
      end

      storable_attribute :duration, :per_style => true, :memoize => true

      def unload
        super
        instance_variables.grep(/@original_/).each do |name|
          instance_variable_set(name, nil)
        end
      end

      protected  # ---------------------------------------------------

      #
      # Return the default processor class to use for this attachment.
      #
      def default_processor_type
        :ffmpeg
      end

      #
      # Overridden to round down to multiples of 2, as required by
      # some codecs.
      #
      def resize_dimensions(original_dimensions, style)
        dimensions = super
        dimensions.map!{|i| i &= -2}
      end

      private  # -----------------------------------------------------

      #
      # Read the original image metadata with ffmpeg.
      #
      def run_examination
        if stream.missing?
          set_defaults
          false
        else
          output = `ffmpeg -i #{stream.path} 2>&1`
          # ffmpeg exits nonzero - don't bother checking status.
          parse_output(output)
          true
        end
      end

      def set_defaults
        @original_duration = 0
        @original_width = 2
        @original_height = 2
        @original_audio_tracks = []
        @original_video_tracks = []
      end

      def parse_output(output)
        result = false
        set_defaults
        io = StringIO.new(output)
        while (line = io.gets)
          case line
          when /^Input #0, (.*?), from '(?:.*)':$/
            result = true
            duration = nil
          when /^  Duration: (\d+):(\d+):(\d+)\.(\d+)/
            duration = $1.to_i.hours + $2.to_i.minutes + $3.to_i.seconds
          when /Stream #(?:.*?): Video: /
            if $' =~ /(\d+)x(\d+)/
              dimensions = [$1.to_i, $2.to_i]
            end
            @original_video_tracks << VideoTrack.new(:dimensions => dimensions, :duration => duration)
          when /Stream #(?:.*?): Audio: (.*?)/
            @original_audio_tracks << AudioTrack.new(:duration => duration)
          end
        end
        if (track = @original_video_tracks.first)
          @original_width, @original_height = *track.dimensions
        end
        if (track = @original_video_tracks.first || @original_audio_tracks.first)
          @original_duration = track.duration
        end
        result
      end

      class Track
        def initialize(attributes={})
          attributes.each do |name, value|
            send("#{name}=", value)
          end
        end

        attr_accessor :duration
      end

      class VideoTrack < Track
        attr_accessor :dimensions
      end

      class AudioTrack < Track
      end
    end
  end
end
