module FastAttachments
  module HasAttachment
    def self.included(base)
      base.extend ClassMethods
      base.class_inheritable_accessor :attachment_reflections
      base.attachment_reflections ||= {}
      base.before_save :process_attachments_for_before_save
      base.after_save :process_attachments_for_after_save
    end

    def attachments
      @attachments ||= {}
    end

    def process_attachment(name, event, *args)
      reflection = attachment_reflections[name].process(self, event, *args)
    end

    def attachment_processor_for(name)
      Processor.class_for(attachment_reflections[name].type)
    end

    def process_attachments_for_before_save
      process_attachments_for_event(:before_save, self)
    end

    def process_attachments_for_after_save
      process_attachments_for_event(:after_save, self)
    end

    def process_attachments_for_event(event, *args)
      self.class.attachment_reflections.each do |name, reflection|
        reflection.process(self, event, *args)
      end
    end

    delegate :attachment_reflections, :to => 'self.class'

    module ClassMethods
      def has_attachment(name_to_types, &block)
        name_to_types.each do |name, type|
          module_eval <<-EOS, __FILE__, __LINE__
            def #{name}
              attachments[:#{name}]
            end
  
            def #{name}=(value)
              process_attachment(:#{name}, :before_assignment, self, value)
              attachments[:#{name}] = value
              process_attachment(:#{name}, :after_assignment, self, value)
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
end
