module Bulldog
  module Attachment
    class None < Maybe
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

      storable_attribute(:updated_at){Time.now}
    end
  end
end
