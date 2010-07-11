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
          storable_attribute :width , :per_style => true, :memoize => true
          storable_attribute :height, :per_style => true, :memoize => true
        end
      end

      #
      # Return the width of the named style.
      #
      # +style_name+ defaults to the attribute's #default_style.
      #
      def width(style_name=nil)
        style_name ||= reflection.default_style
        if style_name.equal?(:original)
          from_examination :@original_width
        else
          dimensions(style_name).at(0)
        end
      end

      #
      # Return the height of the named style.
      #
      # +style_name+ defaults to the attribute's #default_style.
      #
      def height(style_name=nil)
        style_name ||= reflection.default_style
        if style_name.equal?(:original)
          from_examination :@original_height
        else
          dimensions(style_name).at(1)
        end
      end

      #
      # Return the aspect ratio of the named style.
      #
      # +style_name+ defaults to the attribute's #default_style.
      #
      def aspect_ratio(style_name=nil)
        style_name ||= reflection.default_style
        if style_name.equal?(:original)
          original_width = from_examination(:@original_width)
          original_height = from_examination(:@original_height)
          original_width.to_f / original_height
        else
          w, h = *dimensions(style_name)
          w.to_f / h
        end
      end

      #
      # Return the width and height of the named style, as a 2-element
      # array.
      #
      def dimensions(style_name=nil)
        style_name ||= reflection.default_style
        if style_name.equal?(:original)
          original_width = from_examination(:@original_width)
          original_height = from_examination(:@original_height)
          [original_width, original_height]
        else
          resize_dimensions(dimensions(:original), reflection.styles[style_name])
        end
      end

      protected  # -----------------------------------------------------

      #
      # Return the dimensions, as an array [width, height], that
      # result from resizing +original_dimensions+ for the given
      # +style+.
      #
      def resize_dimensions(original_dimensions, style)
        if style.filled?
          style.dimensions
        else
          original_aspect_ratio = original_dimensions[0].to_f / original_dimensions[1]
          target_aspect_ratio = style.dimensions[0].to_f / style.dimensions[1]
          if original_aspect_ratio > target_aspect_ratio
            width = style.dimensions[0]
            height = (width / original_aspect_ratio).round
          else
            height = style.dimensions[1]
            width = (height * original_aspect_ratio).round
          end
          [width, height]
        end
      end
    end
  end
end
