module Bulldog
  module Attachment
    def self.types_to_classes  #:nodoc:
      @types_to_classes ||= {}
    end
  end
end

require 'bulldog/attachment/maybe'
require 'bulldog/attachment/has_dimensions'
require 'bulldog/attachment/base'
require 'bulldog/attachment/none'
require 'bulldog/attachment/image'
require 'bulldog/attachment/video'
require 'bulldog/attachment/pdf'
require 'bulldog/attachment/unknown'

module Bulldog
  module Attachment
    #
    # Return a new attachment of the specified type.
    #
    # If +type+ is nil, then the returned attachment will be None (if
    # the stream is missing), or Base (otherwise - i.e., if the stream
    # represents a file that exists).
    def self.of_type(type, record, name, stream)
      if type.nil?
        klass = stream.missing? ? None : Unknown
      else
        klass = class_from_type(type)
      end
      klass.new(record, name, stream)
    end

    #
    # Return a None attachment for the given record and name.
    #
    def self.none(record, name)
      None.new(record, name, nil)
    end

    #
    # Return the class corresponding to the given type.
    #
    def self.class_from_type(type)
      types_to_classes[type]
    end
  end
end
