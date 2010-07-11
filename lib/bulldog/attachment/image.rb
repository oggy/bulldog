module Bulldog
  module Attachment
    class Image < Base
      handle :image
      include HasDimensions

      def unload
        super
        @original_width = @original_height = nil
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
          @original_width, @original_height = 1, 1
          false
        else
          output = `identify -format "%w %h %[exif:Orientation]" #{stream.path} 2> /dev/null`
          if $?.success? && output.present?
            width, height, orientation = *output.scan(/(\d+) (\d+) (\d?)/).first.map{|s| s.to_i}
            rotated = (5..8).include?(orientation)
            @original_width  = rotated ? height : width
            @original_height = rotated ? width : height
            true
          else
            Bulldog.logger.warn "command failed (#{$?.exitstatus})"
            @original_width, @original_height = 1, 1
            false
          end
        end
      end
    end
  end
end
