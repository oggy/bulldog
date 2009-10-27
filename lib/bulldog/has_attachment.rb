module Bulldog
  module HasAttachment
    def self.included(base)
      base.extend ClassMethods
      base.class_inheritable_accessor :attachment_reflections
      base.attachment_reflections ||= {}

      # We need to store the attachment changes ourselves, since
      # they're unavailable in an after_save.
      base.before_save :store_attachment_changes
      base.after_save :save_attachments
      base.after_save :clear_attachment_changes

      base.after_destroy :destroy_attachments

      # Force initialization of attachments, as #destroy will freeze
      # the attributes afterwards.
      base.before_destroy :initialize_remaining_attachments

      %w[validation save create update].each do |event|
        base.send("before_#{event}", "process_attachments_for_before_#{event}")
        base.send("after_#{event}", "process_attachments_for_after_#{event}")
      end
    end

    def save_attachments
      attachment_reflections.each do |name, reflection|
        next unless @attachment_changes.include?(name)
        old, new = @attachment_changes[name]
        old.destroy
        new.save
      end
    end

    def destroy_attachments
      attachment_reflections.each do |name, reflection|
        attachment_for(name).destroy
      end
    end

    def process_attachment(name, event, *args)
      reflection = attachment_reflections[name] or
        raise ArgumentError, "no such attachment: #{name}"
      attachment_for(name).process(event, *args)
    end

    def attachment_reflection_for(name)
      self.class.attachment_reflections[name]
    end

    private  # -------------------------------------------------------

    def attachment_for(name)
      read_attribute(name) or
        initialize_attachment(name)
    end

    def initialize_attachment(name)
      if new_record?
        value = nil
      else
        original_path = original_path(name)
        if File.exist?(original_path)
          value = UnopenedFile.new(original_path)
        else
          value = nil
        end
      end
      attachment = Attachment.new(self, name, value)
      # Take care here not to mark the attribute as dirty.
      write_attribute_without_dirty(name, attachment)
    end

    def original_path(name)
      reflection = attachment_reflection_for(name)
      template = reflection.path_template
      style = reflection.styles[:original]
      Interpolation.interpolate(template, self, name, style)
    end

    def assign_attachment(name, value)
      unless attachment_for(name).value == value
        attachment = Attachment.new(self, name, value)
        attachment.set_file_attributes
        write_attribute(name, attachment)
      end
    end

    def store_attachment_changes
      @attachment_changes = {}
      attachment_reflections.each do |name, reflection|
        if attribute_changed?(name.to_s)
          @attachment_changes[name] = attribute_change(name.to_s)
        end
      end
    end

    def clear_attachment_changes
      remove_instance_variable :@attachment_changes
    end

    def process_attachments_for_event(event, *args)
      self.class.attachment_reflections.each do |name, reflection|
        attachment_for(reflection.name).process(event, *args)
      end
    end

    def initialize_remaining_attachments
      self.attachment_reflections.each do |name, reflection|
        attachment_for(name)  # force initialization
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
            assign_attachment(:#{name}, value)
          end

          def #{name}?
            !!attachment_for(:#{name}).value
          end
        EOS
      end
    end
  end
end
