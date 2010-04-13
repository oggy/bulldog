module Bulldog
  module Attachment
    class Image < Base
      handle :image

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
        if style_name.equal?(:original)
          from_examination :original_dimensions
        else
          style = reflection.styles[style_name]
          target_dimensions = style[:size].split(/x/).map{|s| s.to_i}
          resized_dimensions(dimensions(:original), target_dimensions, style[:filled])
        end
      end

      include HasDimensions

      def unload
        super
        @original_dimensions = nil
      end

      protected  # ---------------------------------------------------

      #
      # Return the default processor class to use for this attachment.
      #
      def default_processor_type
        :image_magick
      end

      #
      # Read the original image metadata with ImageMagick's identify
      # command.
      #
      def run_examination
        if stream.missing?
          @original_dimensions = [1, 1]
          false
        else
          output = `identify -format "%w %h %[exif:Orientation]" #{stream.path} 2> /dev/null`
          if $?.success? && output.present?
            width, height, orientation = *output.scan(/(\d+) (\d+) (\d?)/).first.map{|s| s.to_i}
            rotated = (orientation-1 & 0x4).nonzero?
            @original_dimensions = rotated ? [height, width] : [width, height]
            true
          else
            Bulldog.logger.warn "command failed (#{$?.exitstatus})"
            @original_dimensions = [1, 1]
            false
          end
        end
      end
    end
  end
end
