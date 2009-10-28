module Bulldog
  module Attachment
    class Image < Base
      #
      # Return the width of the image.
      #
      def width
        dimensions[0]
      end

      #
      # Return the height of the image.
      #
      def height
        dimensions[1]
      end

      #
      # Return the width and height of the image, as a 2-element
      # array.
      #
      def dimensions
        @dimensions ||= `identify -format "%w %h" #{stream.path}`.scan(/\d+/).map(&:to_i)
      end

      #
      # Return the aspect ratio of the image.
      #
      def aspect_ratio
        width.to_f / height
      end

      protected  # ---------------------------------------------------

      #
      # Return the default processor class to use for this attachment.
      #
      def default_processor_type
        :image_magick
      end
    end
  end
end
