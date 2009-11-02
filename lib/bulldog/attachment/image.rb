module Bulldog
  module Attachment
    class Image < Base
      #
      # Return the width of the image.
      #
      def width
        @width ||= dimensions[0]
      end

      #
      # Return the height of the image.
      #
      def height
        @height ||= dimensions[1]
      end

      #
      # Return the aspect ratio of the image.
      #
      def aspect_ratio
        @aspect_ratio ||= width.to_f / height
      end

      #
      # Return the width and height of the image, as a 2-element
      # array.
      #
      def dimensions
        @dimensions ||= `identify -format "%w %h" #{stream.path}`.scan(/\d+/).map(&:to_i)
      end

      storable_attribute :width
      storable_attribute :height
      storable_attribute :aspect_ratio
      storable_attribute :dimensions, :cast => true

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
