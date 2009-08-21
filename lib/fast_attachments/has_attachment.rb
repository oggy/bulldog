module FastAttachments
  module HasAttachment
    def self.included(mod)
      mod.extend ClassMethods
    end

    def attachments
      @attachments ||= {}
    end

    module ClassMethods
      def has_attachment(name, options={})
        module_eval <<-EOS
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
      end
    end
  end
end
