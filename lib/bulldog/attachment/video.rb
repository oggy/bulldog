module Bulldog
  module Attachment
    class Video < Base
      protected  # ---------------------------------------------------

      #
      # Return the default processor class to use for this attachment.
      #
      def default_processor_type
        :ffmpeg
      end
    end
  end
end
