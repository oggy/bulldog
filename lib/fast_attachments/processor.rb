module FastAttachments
  module Processor
    #
    # Associate a processor with a type:
    #
    #   process :photo, :with => MyPhotoProcessor
    #
    def self.register(type, klass)
      @type_map[type] = klass
    end
    @type_map = {}

    #
    # Return the class that processes the given type.
    #
    def self.class_for(type)
      @type_map[type]
    end
  end
end

require 'fast_attachments/processor/base'
require 'fast_attachments/processor/photo'
