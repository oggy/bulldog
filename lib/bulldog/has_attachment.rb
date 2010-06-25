module Bulldog
  module HasAttachment
    def self.included(base)
      base.extend ClassMethods
      base.instance_variable_set(:@attachment_reflections, {})

      # We need to store the attachment changes ourselves, since
      # they're unavailable in an after_save.
      base.before_save :store_original_attachments
      base.after_save :save_attachments
      base.after_save :clear_original_attachments

      base.before_save :update_attachment_timestamps
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
        original_attachment = @original_attachments[name] and
          original_attachment.destroy
        _attachment_for(name).save
      end
    end

    def destroy_attachments
      attachment_reflections.each do |name, reflection|
        _attachment_for(name).destroy
      end
    end

    def update_attachment_timestamps
      attachment_reflections.each do |name, reflection|
        next unless send("#{name}_changed?")
        setter = "#{name}_updated_at="
        if respond_to?(setter)
          send(setter, Time.now)
        end
      end
    end

    def process_attachment(name, event, *args)
      reflection = attachment_reflections[name] or
        raise ArgumentError, "no such attachment: #{name}"
      _attachment_for(name).process(event, *args)
    end

    def attachment_reflection_for(name)
      self.class.attachment_reflections[name]
    end

    private  # -------------------------------------------------------

    # Prefixed with '_', as it would collide with paperclip otherwise.
    def _attachment_for(name)
      read_attribute(name) or
        initialize_attachment(name)
    end

    def initialize_attachment(name)
      if new_record?
        value = nil
      else
        reflection = attachment_reflection_for(name)
        file_name_column = reflection.column_name_for_stored_attribute(:file_name)
        file_name = file_name_column ? send(file_name_column) : nil
        if file_name_column && file_name.nil?
          value = nil
        else
          template = reflection.path_template
          style = reflection.styles[:original]
          original_path = Interpolation.interpolate(template, self, name, style, :basename => file_name)
          if File.exist?(original_path)
            value = SavedFile.new(original_path, :file_name => file_name)
          else
            if file_name_column
              value = MissingFile.new(:file_name => file_name)
            else
              value = nil
            end
          end
        end
      end

      attachment = make_attachment_for(name, value)
      write_attribute_without_dirty(name, attachment)
      attachment.read_storable_attributes
      attachment
    end

    def assign_attachment(name, value)
      old_attachment = _attachment_for(name)
      unless old_attachment.value == value
        old_attachment.unload
        new_attachment = make_attachment_for(name, value)
        new_attachment.load
        write_attribute(name, new_attachment)
      end
    end

    def make_attachment_for(name, value)
      return Attachment.none(self, name) if value.nil?
      stream = Stream.new(value)
      reflection = attachment_reflection_for(name)
      type = reflection.detect_attachment_type(self, stream)
      Attachment.of_type(type, self, name, stream)
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
      # This can be unset if the record is resaved between store and
      # clear (e.g., in an after_save: store, save, store, clear, clear).
      if instance_variable_defined?(:@original_attachments)
        remove_instance_variable :@original_attachments
      end
    end

    def process_attachments_for_event(event, *args)
      self.class.attachment_reflections.each do |name, reflection|
        _attachment_for(reflection.name).process(event, *args)
      end
    end

    def initialize_remaining_attachments
      self.attachment_reflections.each do |name, reflection|
        _attachment_for(name)  # force initialization
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
      def attachment_reflections
        @attachment_reflections ||=
          begin
            hash = {}
            superhash = superclass.attachment_reflections
            superhash.map do |name, reflection|
              hash[name] = reflection.clone
            end
            hash
          end
      end

      #
      # Declare that this model has an attachment.
      #
      # TODO: example that shows all the options.
      #
      def has_attachment(name, &block)
        reflection = attachment_reflections[name] || Reflection.new(self, name)
        reflection.configure(&block)
        attachment_reflections[name] = reflection
        define_attachment_accessors(reflection.name)
        define_attachment_attribute_methods(reflection.name)
      end

      def define_attachment_accessors(name)
        module_eval <<-EOS, __FILE__, __LINE__
          def #{name}
            _attachment_for(:#{name})
          end

          def #{name}=(value)
            assign_attachment(:#{name}, value)
          end

          def #{name}?
            _attachment_for(:#{name}).present?
          end
        EOS
      end

      def define_attachment_attribute_methods(name)
        # HACK: Without this, methods defined via
        # #attribute_method_suffix (e.g., #ATTACHMENT_changed?) won't
        # be defined unless the attachment is assigned first.
        # ActiveRecord appears to give us no other way without
        # defining an after_initialize, which is slow.
        attribute_method_suffixes.each do |suffix|
          next unless suffix[0] == ?_  # skip =, ?.
          class_eval <<-EOS
            def #{name}#{suffix}(*args, &block)
              attribute#{suffix}('#{name}', *args, &block)
            end
          EOS
        end
      end
    end
  end
end
