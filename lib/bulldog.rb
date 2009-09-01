require 'bulldog/has_attachment'
require 'bulldog/validations'
require 'bulldog/attachment_reflection'
require 'bulldog/attachment_attribute'
require 'bulldog/configuration'
require 'bulldog/style'
require 'bulldog/style_set'
require 'bulldog/unopened_file'
require 'bulldog/processor'

module Bulldog
  class << self
    #
    # Logger object to log to.  Set to nil to omit logging.
    #
    attr_accessor :logger
  end
end
