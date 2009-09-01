module Bulldog
  module HasAttachment
    def self.included(base)
      base.extend ClassMethods
      base.class_inheritable_accessor :attachment_reflections
      base.attachment_reflections ||= {}

      %w[validation save create update].each do |event|
        base.send("before_#{event}", "process_attachments_for_before_#{event}")
        base.send("after_#{event}", "process_attachments_for_after_#{event}")
      end
    end

    def attachment_attribute(name)
      @attachment_attributes ||= {}
      @attachment_attributes[name] ||= AttachmentAttribute.new(self, name)
    end

    def process_attachment(name, event, *args)
      reflection = attachment_reflections[name] or
        raise ArgumentError, "no such attachment: #{name}"
      attachment_attribute(name).process(event, *args)
    end

    def process_attachments_for_event(event, *args)
      self.class.attachment_reflections.each do |name, reflection|
        attachment_attribute(reflection.name).process(event, *args)
      end
    end

    %w[validation save create update].each do |event|
      module_eval <<-EOS
        def process_attachments_for_before_#{event}
          process_attachments_for_event(:before_#{event})
        end
        def process_attachments_for_after_#{event}
          process_attachments_for_event(:after_#{event})
        end
      EOS
    end

    delegate :attachment_reflections, :to => 'self.class'

    module ClassMethods
      #
      # Declare that this model has an attachment.
      #
      # TODO: example that shows all the options.
      #
      def has_attachment(name_with_optional_type, &block)
        reflection = AttachmentReflection.new(self, name_with_optional_type, &block)
        define_attachment_accessors(reflection.name)
      end

      def define_attachment_accessors(name)
        module_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            attachment_attribute(:#{name}).get
            read_attribute(:#{name})
          end

          def #{name}=(value)
            process_attachment(:#{name}, :before_assignment, value)
            attachment_attribute(:#{name}).set(value)
            process_attachment(:#{name}, :after_assignment, value)
          end

          def #{name}?
            !!#{name}
          end
        EOS
      end
    end
  end
end
