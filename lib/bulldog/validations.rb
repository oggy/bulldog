module Bulldog
  module Validations
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def validates_attachment_presence(name, options={})
        validates_each(name, options) do |record, attribute, attachment|
          attachment.present? && attachment.size > 0 or
            record.errors.add attribute, options[:message] || :attachment_blank
        end
      end

      def validates_attachment_size(name, options={})
        if (range = options.delete(:in))
          options[:greater_than] = range.min - 1
          options[:less_than   ] = range.max + 1
        end
        validates_each(name, options) do |record, attribute, attachment|
          if attachment.present?
            file_size = attachment.size
            if options[:greater_than]
              file_size > options[:greater_than] or
                record.errors.add attribute, options[:message] || :attachment_too_small
            end
            if options[:less_than]
              file_size < options[:less_than] or
                record.errors.add attribute, options[:message] || :attachment_too_large
            end
          end
        end
      end

      def validates_attachment_type(name, options={})
        validates_each(name, options) do |record, attribute, attachment|
          if attachment.present?
            if (pattern = options[:matches])
              attachment.content_type =~ pattern or
                record.errors.add attribute, options[:message] || :wrong_type
            end
          end
        end
      end
    end
  end
end
