require 'fast_attachments'

ActiveRecord::Base.send :include, FastAttachments::HasAttachment
