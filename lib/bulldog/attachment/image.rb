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
          `identify -format "%w %h" #{stream.path} 2> /dev/null`.scan(/\d+/).map(&:to_i)
        else
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
