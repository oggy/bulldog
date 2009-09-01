module Bulldog
  module Validations
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def validates_attachment_presence(name, options={})
        validates_each(name, options) do |record, attribute, value|
          value.size > 0 or
            record.errors.add attribute, options[:message] || :attachment_blank
        end
      end

      def validates_attachment_size(name, options={})
        if (range = options.delete(:in))
          options[:greater_than] = range.min - 1
          options[:less_than   ] = range.max + 1
        end
        validates_each(name, options) do |record, attributes, value|
          file_size = value.is_a?(StringIO) ? value.size : File.size(value.path)
          if options[:greater_than]
            file_size > options[:greater_than] or
              record.errors.add attributes, options[:message] || :attachment_too_small
          end
          if options[:less_than]
            file_size < options[:less_than] or
              record.errors.add attributes, options[:message] || :attachment_too_large
          end
        end
      end
    end
  end
end
