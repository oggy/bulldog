require 'fast_attachments/has_attachment'
require 'fast_attachments/attachment_attribute'
require 'fast_attachments/configuration'
require 'fast_attachments/style'
require 'fast_attachments/style_set'
require 'fast_attachments/unopened_file'
require 'fast_attachments/processor'

module FastAttachments
  class << self
    #
    # Logger object to log to.  Set to nil to omit logging.
    #
    attr_accessor :logger
  end
end
