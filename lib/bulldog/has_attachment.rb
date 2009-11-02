module Bulldog
  module HasAttachment
    def self.included(base)
      base.extend ClassMethods
      base.class_inheritable_accessor :attachment_reflections
      base.attachment_reflections ||= {}

      # We need to store the attachment changes ourselves, since
      # they're unavailable in an after_save.
      base.before_save :store_original_attachments
      base.after_save :save_attachments
      base.after_save :clear_original_attachments

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
        original_attachment = @original_attachments[name] or
          next
        original_attachment.destroy
        attachment_for(name).save
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
          reflection = attachment_reflection_for(name)
          if (file_name_column = reflection.column_name_for_stored_attribute(:file_name))
            file_name = send(file_name_column)
          end
          value = UnopenedFile.new(original_path, :file_name => file_name)
        else
          value = nil
        end
      end
      attachment = Attachment.new(self, name, value)
      # Take care here not to mark the attribute as dirty.
      write_attribute_without_dirty(name, attachment)
      attachment.read_storable_attributes
      attachment
    end

    def original_path(name)
      reflection = attachment_reflection_for(name)
      template = reflection.path_template
      style = reflection.styles[:original]
      Interpolation.interpolate(template, self, name, style)
    end

    def assign_attachment(name, value)
      old_attachment = attachment_for(name)
      unless old_attachment.value == value
        old_attachment.clear_stored_attributes
        new_attachment = Attachment.new(self, name, value)
        new_attachment.set_stored_attributes
        write_attribute(name, new_attachment)
      end
    end

    def store_original_attachments
      @original_attachments = {}
      attachment_reflections.each do |name, reflection|
        if send("#{name}_changed?")
          @original_attachments[name] = send("#{name}_was")
        end
      end
    end

    def clear_original_attachments
      remove_instance_variable :@original_attachments
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
