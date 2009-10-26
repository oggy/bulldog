module Bulldog
  module HasAttachment
    def self.included(base)
      base.extend ClassMethods
      base.class_inheritable_accessor :attachment_reflections
      base.attachment_reflections ||= {}

      base.after_save :save_attachments
      base.after_destroy :destroy_attachments
      %w[validation save create update].each do |event|
        base.send("before_#{event}", "process_attachments_for_before_#{event}")
        base.send("after_#{event}", "process_attachments_for_after_#{event}")
      end
    end

    def save_attachments
      attachment_reflections.each do |name, reflection|
        attachment_for(name).save
      end
    end

    def destroy_attachments
      attachment_reflections.each do |name, reflection|
        attachment_for(name).destroy
      end
    end

    def attachment_for(name)
      @attachments ||= {}
      attribute_class = self.class.attachment_reflections[name].attachment_class
      @attachments[name] ||= attribute_class.new(self, name)
    end

    def process_attachment(name, event, *args)
      reflection = attachment_reflections[name] or
        raise ArgumentError, "no such attachment: #{name}"
      attachment_for(name).process(event, *args)
    end

    def process_attachments_for_event(event, *args)
      self.class.attachment_reflections.each do |name, reflection|
        attachment_for(reflection.name).process(event, *args)
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
      def has_attachment(name, &block)
        reflection = Reflection.new(self, name, &block)
        attachment_reflections[name] = reflection
        define_attachment_accessors(reflection.name)
      end

      def define_attachment_accessors(name)
        module_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            attachment_for(:#{name})
          end

          def #{name}=(value)
            process_attachment(:#{name}, :before_assignment, value)
            attachment_for(:#{name}).set(value)
            process_attachment(:#{name}, :after_assignment, value)
          end

          def #{name}?
            attachment_for(:#{name}).query
          end
        EOS
      end
    end
  end
end
