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

        if block_given?
          configurer = Configurer.new(self, options)
          configurer.instance_eval(&block)
        end
        reflection = Reflection.new(name, options)

        attachment_reflections[name] = reflection
      end
    end

    class Configurer
      def initialize(klass, options)
        @klass = klass
        @options = options
      end

      attr_reader :options
      attr_accessor :styles

      def style(name, attributes)
        options[:styles] ||= {}
        options[:styles][name] = attributes
      end

      def styles
        options[:styles]
      end
    end
  end
end
