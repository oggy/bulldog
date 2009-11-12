module Bulldog
  module Attachment
    #
    # Module for dealing with dimensions.
    #
    # Note that due to the way stored attributes are implemented, this
    # module must be included after the definition of #dimensions.
    #
    module HasDimensions
      def self.included(base)
        super
        base.class_eval do
          storable_attribute :width       , :per_style => true, :memoize => true
          storable_attribute :height      , :per_style => true, :memoize => true
          storable_attribute :aspect_ratio, :per_style => true, :memoize => true
          storable_attribute :dimensions  , :per_style => true, :memoize => true, :cast => true
        end
      end

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
      def dimensions
        raise 'abstract method called'
      end

      protected  # -----------------------------------------------------

      #
      # Return the dimensions, as an array [width, height], that
      # result from resizing +original_dimensions+ to
      # +target_dimensions+.  If fill is true, assume the final image
      # will fill the target box.  Otherwise the aspect ratio will be
      # maintained.
      #
      def resized_dimensions(original_dimensions, target_dimensions, fill)
        if fill
          target_dimensions
        else
          original_aspect_ratio = original_dimensions[0].to_f / original_dimensions[1]
          target_aspect_ratio = target_dimensions[0].to_f / target_dimensions[1]
          if original_aspect_ratio > target_aspect_ratio
            width = target_dimensions[0]
            height = (width / original_aspect_ratio).round
          else
            height = target_dimensions[1]
            width = (height * original_aspect_ratio).round
          end
          [width, height]
        end
      end
    end
  end
end
