require 'bulldog/has_attachment'
require 'bulldog/validations'
require 'bulldog/reflection'
require 'bulldog/attribute'
require 'bulldog/configuration'
require 'bulldog/style'
require 'bulldog/style_set'
require 'bulldog/interpolation'
require 'bulldog/unopened_file'
require 'bulldog/processor'

module Bulldog
  class << self
    #
    # Logger object to log to.  Set to nil to omit logging.
    #
    attr_accessor :logger

    #
    # The default path template to use.  See the #path configuration
    # option for #has_attachment.
    #
    attr_accessor :default_path
  end
end
