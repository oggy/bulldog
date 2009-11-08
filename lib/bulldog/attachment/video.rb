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
      # For :original, this is based on the output of ImageMagick's
      # <tt>identify</tt> command.  Other styles are calculated from
      # the original style's dimensions, plus the style's :size and
      # :filled attributes.
      #
      # +style_name+ defaults to the attribute's #default_style.
      #
      def dimensions(style_name)
        if style_name == :original
          if stream.missing?
            [1, 1]
          else
            examine_file
            if @original_video_tracks.empty?
              [1, 1]
            else
              @original_video_tracks.first.dimensions
            end
          end
        else
          # TODO: perform video cropping if :filled is given.
          style = reflection.styles[style_name]
          box_size = style[:size].split(/x/).map(&:to_i)
          if style[:filled]
            box_size
          else
            original_aspect_ratio = aspect_ratio(:original)
            box_aspect_ratio = box_size[0].to_f / box_size[1]
            if original_aspect_ratio > box_aspect_ratio
              width = box_size[0]
              height = (width / original_aspect_ratio).round
            else
              height = box_size[1]
              width = (height * original_aspect_ratio).round
            end
            [width, height]
          end
        end
      end

      def duration(style_name)
        # TODO: support styles with different durations
        if stream.missing?
          0
        else
          examine_file
          @original_duration
        end
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
      def examine_file
        return if examined?
        @examined = true

        output = `ffmpeg -i #{stream.path} 2>&1`
        parse_output(output)
        dimensions = @original_video_tracks.first
      end

      def parse_output(output)
        @original_duration = 0
        @original_video_tracks = []
        @original_audio_tracks = []
        io = StringIO.new(output)
        while (line = io.gets)
          case line
          when /^Input #0, (.*?), from '(?:.*)':$/
            format = $1
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
      end

      def examined?
        @examined
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
