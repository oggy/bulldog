require 'bulldog/attachment/base'
require 'bulldog/attachment/none'
require 'bulldog/attachment/image'

module Bulldog
  module Attachment
    #
    # Return an attachment object for the given record, name, and
    # value.
    #
    def self.new(record, name, value)
      klass = value.nil? ? None : Base
      klass.new(record, name, value)
    end
  end
end
