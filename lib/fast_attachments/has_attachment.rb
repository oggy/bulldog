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
      callback = self.class.attachment_reflections[name].events[event]
      instance_exec(*args, &callback)
    end

    module ClassMethods
      def has_attachment(name, options={}, &block)
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

        reflection = Reflection.new(self, name, options)
        reflection.instance_eval(&block) if block_given?
        attachment_reflections[name] = reflection
      end
    end
  end
end
