module Bulldog
  module Attachment
    class Image < Base
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
        if style_name.equal?(:original)
          examine
          @original_dimensions
        else
          style = reflection.styles[style_name]
          target_dimensions = style[:size].split(/x/).map(&:to_i)
          resized_dimensions(dimensions(:original), target_dimensions, style[:filled])
        end
      end

      storable_attribute :width       , :per_style => true, :memoize => true
      storable_attribute :height      , :per_style => true, :memoize => true
      storable_attribute :aspect_ratio, :per_style => true, :memoize => true
      storable_attribute :dimensions  , :per_style => true, :memoize => true, :cast => true

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
            width, height, orientation = *output.scan(/(\d+) (\d+) (\d?)/).first.map(&:to_i)
            rotated = (orientation & 0x4).nonzero?
            @original_dimensions ||= rotated ? [height, width] : [width, height]
            true
          else
            Bulldog.logger.warn "command failed (#{$?.exitstatus})"
            @original_dimensions = [1, 1]
            false
          end
        end
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
    end
  end
end
