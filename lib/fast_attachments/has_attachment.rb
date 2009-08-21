module FastAttachments
  module HasAttachment
    def self.included(base)
      base.extend ClassMethods
      base.class_inheritable_accessor :attachments
      base.attachments ||= {}
    end

    def attachments
      @attachments ||= {}
    end

    module ClassMethods
      def has_attachment(name, options={})
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

        attachments[name] = Reflection.new(name, options)
      end
    end
  end
end
