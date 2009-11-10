require 'bulldog/error'
require 'bulldog/has_attachment'
require 'bulldog/validations'
require 'bulldog/reflection'
require 'bulldog/attachment'
require 'bulldog/style'
require 'bulldog/style_set'
require 'bulldog/interpolation'
require 'bulldog/saved_file'
require 'bulldog/missing_file'
require 'bulldog/processor'
require 'bulldog/stream'
require 'bulldog/vector2'
require 'bulldog/run'

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
    attr_accessor :default_path_template

    #
    # The default url template to use.  See the #url configuration
    # option for #has_attachment.
    #
    attr_accessor :default_url_template
  end

  self.logger = nil
  self.default_path_template = nil
  self.default_url_template = "/assets/:class/:id.:style.:extension"

  extend Run
end

ActiveRecord::Base.send :include, Bulldog::HasAttachment
ActiveRecord::Base.send :include, Bulldog::Validations
