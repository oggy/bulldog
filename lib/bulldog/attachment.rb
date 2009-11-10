require 'bulldog/attachment/maybe'
require 'bulldog/attachment/base'
require 'bulldog/attachment/none'
require 'bulldog/attachment/image'
require 'bulldog/attachment/video'

module Bulldog
  module Attachment
    #
    # Return an attachment object for the given record, name, and
    # value.
    #
    def self.new(record, name, value)
      klass =
        if value.blank?
          None
        else
          stream = Stream.new(value)
          case stream.content_type[/\w+/]
          when 'image'
            Image
          when 'video'
            Video
          else
            [Video, Image, Base].each do |klass|
              attachment = klass.try(record, name, stream) and
                return attachment
            end
            Base
          end
        end
      attachment = klass.new(record, name, stream)
    end

    def self.missing(type, record, name, value)
      stream = Stream.new(value)
      klass = class_from_type(type)
      klass.new(record, name, stream)
    end

    #
    # Return the class corresponding to the given type.
    #
    def self.class_from_type(type)
      const_get(type.to_s.camelize)
    end
  end
end
