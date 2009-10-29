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
            elsif (specifier = options[:is])
              if specifier.is_a?(Symbol)
                attachment_class = Attachment.class_from_type(specifier)
                attachment.is_a?(attachment_class) or
                  record.errors.add attribute, options[:message] || :wrong_type
              else
                parse_mime_type = lambda do |string|
                  mime_type, parameter_string = string.to_s.split(/;/)
                  parameters = {}
                  (parameter_string || '').split(/,/).each do |pair|
                    name, value = pair.strip.split(/=/)
                    parameters[name] = value
                  end
                  [mime_type, parameters]
                end

                expected_type, expected_parameters = parse_mime_type.call(specifier)
                actual_type, actual_parameters = parse_mime_type.call(attachment.content_type)
                expected_type == actual_type && expected_parameters.all?{|k,v| actual_parameters[k] == v} or
                  record.errors.add attribute, options[:message] || :wrong_type
              end
            end
          end
        end
      end
    end
  end
end
