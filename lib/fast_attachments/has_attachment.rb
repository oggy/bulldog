module FastAttachments
  module HasAttachment
    def self.included(base)
      base.extend ClassMethods
      base.class_inheritable_accessor :attachment_reflections
      base.attachment_reflections ||= {}
    end

    def attachments
      @attachments ||= {}
    end

    def process_attachment(name, event, *args)
      callback = attachment_reflections[name].events[event]
      attachment_processor_for(name).instance_exec(*args, &callback)
    end

    def attachment_processor_for(name)
      Processor.class_for(attachment_reflections[name].type)
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
              attachments[:#{name}] = value
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
