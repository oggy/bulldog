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
      end

      def destroy
      end

      def process(event, *args)
      end

      def set_file_attributes
        set_file_attribute(:file_name){nil}
        set_file_attribute(:content_type){nil}
        set_file_attribute(:file_size){nil}
        set_file_attribute(:updated_at){Time.now}
      end
    end
  end
end
