module Bulldog
  module Attachment
    class Pdf < Base
      handle :pdf
      include HasDimensions

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
          output = `identify -format "%w %h" #{stream.path}[0] 2> /dev/null`
          if $?.success? && output.present?
            @original_width, @original_height = *output.scan(/(\d+) (\d+)/).first.map{|s| s.to_i}
            true
          else
            Bulldog.logger.warn "command failed (#{$?.exitstatus})"
            false
          end
        end
      end
    end
  end
end
