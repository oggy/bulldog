module Bulldog
  module Attachment
    class None < Maybe
      handle :none

      #
      # Return true.  (Overrides ActiveSupport's Object#blank?)
      #
      # This means #present? will be false too.
      #
      def blank?
        true
      end

      def path(style_name = reflection.default_style)
        nil
      end

      def url(style_name = reflection.default_style)
        nil
      end

      def size
        nil
      end

      def save
        return if saved?
        delete_files_and_empty_parent_directories
      end

      def destroy
      end

      def process(event, *args)
      end
    end
  end
end
