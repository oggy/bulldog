module FastAttachments
  module Processor
    #
    # Associate a processor with a type:
    #
    #   process :photo, :with => MyPhotoProcessor
    #
    def self.process(type, params)
      @type_map[type] = params[:with] or
        raise ArgumentError, ":with parameter required"
    end
    @type_map = {}

    def self.class_for(type)
      @type_map[type]
    end
  end
end

require 'fast_attachments/processor/base'
require 'fast_attachments/processor/photo'
