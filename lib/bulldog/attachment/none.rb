module Bulldog
  module Attachment
    class None < Base
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
        delete_files_and_empty_parent_directories
      end

      def destroy
      end

      def process(event, *args)
      end

      def set_stored_attributes
        set_stored_attribute(:file_name){nil}
        set_stored_attribute(:content_type){nil}
        set_stored_attribute(:file_size){nil}
        set_stored_attribute(:updated_at){Time.now}
      end
    end
  end
end
