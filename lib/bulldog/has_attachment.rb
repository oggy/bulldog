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

    def attachments
      @attachments ||= {}
    end

    def process_attachment(name, event, *args)
      reflection = attachment_reflections[name] or
        raise ArgumentError, "no such attachment: #{name}"
      reflection.process(event, self, *args)
    end

    def process_attachments_for_event(event, *args)
      self.class.attachment_reflections.each do |name, reflection|
        reflection.process(event, self, *args)
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
        AttachmentReflection.new(self, name_with_optional_type, &block)
      end
    end
  end
end
