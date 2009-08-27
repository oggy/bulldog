require 'bulldog'

ActiveRecord::Base.send :include, Bulldog::HasAttachment
