module Bulldog
  module Attachment
    class Video < Base
      #
      # Return the width of the named style.
      #
      # +style_name+ defaults to the attribute's #default_style.
      #
      def width(style_name)
        dimensions(style_name)[0]
      end

      #
      # Return the height of the named style.
      #
      # +style_name+ defaults to the attribute's #default_style.
      #
      def height(style_name)
        dimensions(style_name)[1]
      end

      #
      # Return the aspect ratio of the named style.
      #
      # +style_name+ defaults to the attribute's #default_style.
      #
      def aspect_ratio(style_name)
        width(style_name).to_f / height(style_name)
      end

      #
      # Return the width and height of the named style, as a 2-element
      # array.
      #
      # This runs ffmpeg for, and only for, the original style.
      #
      # +style_name+ defaults to the attribute's #default_style.
      #
      def dimensions(style_name)
        video_tracks(style_name).first.dimensions
      end

      #
      # Return the duration of the named style, as an
      # ActiveSupport::Duration.
      #
      # This runs ffmpeg for, and only for, the original style.
      #
      # +style_name+ defaults to the attribute's #default_style.
      #
      def duration(style_name)
        # TODO: support styles with different durations
        if stream.missing?
          0
        else
          examine
          @original_duration
        end
      end

      #
      # Return the video tracks of the named style, as an array of
      # VideoTrack objects.
      #
      # Each VideoTrack has:
      #
      #  * <tt>#dimension</tt> - the dimensions of the video track,
      #    [width, height].
      #
      def video_tracks(style_name=nil)
        style_name ||= reflection.default_style
        if style_name == :original
          if stream.missing?
            [VideoTrack.new(:dimensions => [1, 1])]
          else
            examine
            if @original_video_tracks.empty?
              @original_video_tracks << VideoTrack.new(:dimensions => [1, 1])
            end
            @original_video_tracks
          end
        else
          style = reflection.styles[style_name]
          target_dimensions = style[:size].split(/x/).map(&:to_i)
          video_tracks(:original).map do |video_track|
            dimensions = resized_dimensions(dimensions(:original), target_dimensions, style[:filled])
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
      def audio_tracks(style_name)
        examine
        @original_audio_tracks
      end

      storable_attribute :width       , :per_style => true, :memoize => true
      storable_attribute :height      , :per_style => true, :memoize => true
      storable_attribute :aspect_ratio, :per_style => true, :memoize => true
      storable_attribute :dimensions  , :per_style => true, :memoize => true, :cast => true
      storable_attribute :duration    , :per_style => true, :memoize => true

      protected  # ---------------------------------------------------

      #
      # Return the default processor class to use for this attachment.
      #
      def default_processor_type
        :ffmpeg
      end

      private  # -----------------------------------------------------

      def serialize_dimensions(dimensions)
        return nil if dimensions.blank?
        dimensions.join('x')
      end

      def deserialize_dimensions(string)
        return nil if string.blank?
        string.scan(/\d+/).map(&:to_i)
      end

      #
      # Read the original image metadata with ffmpeg.
      #
      def run_examination
        return false if stream.missing?
        output = `ffmpeg -i #{stream.path} 2>&1`
        parse_output(output)
      end

      def parse_output(output)
        result = false
        @original_duration = 0
        @original_video_tracks = []
        @original_audio_tracks = []
        io = StringIO.new(output)
        while (line = io.gets)
          case line
          when /^Input #0, (.*?), from '(?:.*)':$/
            result = true
          when /^  Duration: (\d+):(\d+):(\d+)\.(\d+)/
            @original_duration = $1.to_i.hours + $2.to_i.minutes + $3.to_i.seconds
          when /Stream #(?:.*?): Video: /
            if $' =~ /(\d+)x(\d+)/
              dimensions = [$1.to_i, $2.to_i]
            end
            @original_video_tracks << VideoTrack.new(:dimensions => dimensions)
          when /Stream #(?:.*?): Audio: (.*?)/
            @original_audio_tracks << AudioTrack.new
          end
        end
        result
      end

      class Track
        def initialize(attributes={})
          attributes.each do |name, value|
            send("#{name}=", value)
          end
        end
      end

      class VideoTrack < Track
        attr_accessor :dimensions
      end

      class AudioTrack < Track
      end
    end
  end
end
