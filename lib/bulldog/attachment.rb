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
            Base
          end
        end
      attachment = klass.new(record, name, stream)
    end
  end
end
