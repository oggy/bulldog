require 'bulldog/util'
module Bulldog
  extend Util
end

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
require 'bulldog/tempfile'
require 'bulldog/stream'
require 'bulldog/vector2'

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

    #
    # Define an interpolation token.
    #
    # If :<token> appears in a path or URL template, the block will be
    # called to get the value to substitute in.  The block will be
    # called with 3 arguments: the record, the attachment name, and
    # the style.
    #
    # Example:
    #
    #     Bulldog.to_interpolate :datestamp do |record, name, style|
    #       Date.today.strftime("%Y%m%d")
    #     end
    #
    def to_interpolate(token, &block)
      Interpolation.to_interpolate(token, &block)
    end

    #
    # Register a custom type detector.
    #
    # When instantiating an attachment, Bulldog will use the
    # configured type detector to work out which type of attachment to
    # use.  This method registers a custom type detector which may be
    # selected in your attachment configuration by just using the
    # name.
    #
    # The given block is passed the record, the attribute name, and
    # the value as a Bulldog::Stream.  The block should return a
    # symbol representing the attachment type.
    #
    # Example:
    #
    #     Bulldog.to_detect_type_by :file_extension do |record, name, stream|
    #       case File.extname(stream.file_name).sub(/\A\./)
    #       when 'jpg', 'png', 'gif', 'tiff'
    #         :image
    #       when 'mpg', 'avi', 'ogv'
    #         :video
    #       when 'pdf'
    #         :pdf
    #       end
    #     end
    #
    def to_detect_type_by(name, &block)
      Reflection.to_detect_type_by(name, &block)
    end
  end

  self.logger = nil
  self.default_path_template = nil
  self.default_url_template = "/assets/:class/:id.:style.:extension"
end

ActiveRecord::Base.send :include, Bulldog::HasAttachment
ActiveRecord::Base.send :include, Bulldog::Validations
