module FastAttachments
  module HasAttachment
    def self.included(base)
      base.extend ClassMethods
      base.class_inheritable_accessor :attachment_reflections
      base.attachment_reflections ||= {}

      base.before_save :process_attachments_for_before_save
      base.after_save :process_attachments_for_after_save
      base.before_create :process_attachments_for_before_create
      base.after_create :process_attachments_for_after_create
      base.before_update :process_attachments_for_before_update
      base.after_update :process_attachments_for_after_update
      base.before_validation :process_attachments_for_before_validation
      base.after_validation :process_attachments_for_after_validation
    end

    def attachments
      @attachments ||= {}
    end

    def process_attachment(name, event, *args)
      attachment_reflections[name].process(self, event, *args)
    end

    def process_attachments_for_event(event, *args)
      self.class.attachment_reflections.each do |name, reflection|
        reflection.process(self, event, *args)
      end
    end

    def self.define_attachment_hooks_for_lifecycle_event(event)
      module_eval <<-EOS
        def process_attachments_for_#{event}
          process_attachments_for_event(:#{event}, self)
        end
      EOS
    end

    define_attachment_hooks_for_lifecycle_event :before_validation
    define_attachment_hooks_for_lifecycle_event :after_validation

    define_attachment_hooks_for_lifecycle_event :before_save
    define_attachment_hooks_for_lifecycle_event :after_save

    define_attachment_hooks_for_lifecycle_event :before_create
    define_attachment_hooks_for_lifecycle_event :after_create

    define_attachment_hooks_for_lifecycle_event :before_update
    define_attachment_hooks_for_lifecycle_event :after_update

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
