module FastAttachments
  module HasAttachment
    def self.included(base)
      base.extend ClassMethods
      base.class_inheritable_accessor :attachment_attributes
      base.attachment_attributes ||= {}

      %w[validation save create update].each do |event|
        base.send("before_#{event}", "process_attachments_for_before_#{event}")
        base.send("after_#{event}", "process_attachments_for_after_#{event}")
      end
    end

    def attachments
      @attachments ||= {}
    end

    def process_attachment(name, event, *args)
      attribute = attachment_attributes[name] or
        raise ArgumentError, "no such attachment: #{name}"
      attribute.process(event, self, *args)
    end

    def process_attachments_for_event(event, *args)
      self.class.attachment_attributes.each do |name, attribute|
        attribute.process(event, self, *args)
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

    delegate :attachment_attributes, :to => 'self.class'

    module ClassMethods
      #
      # Declare that this model has an attachment.
      #
      # TODO: example that shows all the options.
      #
      def has_attachment(name_with_optional_type, &block)
        AttachmentAttribute.new(self, name_with_optional_type, &block)
      end
    end
  end
end
