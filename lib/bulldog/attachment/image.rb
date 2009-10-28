module Bulldog
  module Attachment
    class Image < Base
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
