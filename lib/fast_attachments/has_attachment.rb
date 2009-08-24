module FastAttachments
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
        if name_with_optional_type.is_a?(Hash)
          name_with_optional_type.size == 1 or
            raise ArgumentError, "hash argument must have exactly 1 key/value"
          name, type = *name_with_optional_type.to_a.first
        else
          name, type = name_with_optional_type, nil
        end

        module_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            attachments[:#{name}]
          end

          def #{name}=(value)
            process_attachment(:#{name}, :before_assignment, value)
            attachments[:#{name}] = value
            process_attachment(:#{name}, :after_assignment, value)
          end

          def #{name}?
            !!attachments[:#{name}]
          end
        EOS

        reflection = Reflection.new(self, name, type)
        reflection.instance_eval(&block) if block_given?
        attachment_reflections[name] = reflection
      end
    end
  end
end
