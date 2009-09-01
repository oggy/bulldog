require 'bulldog'

ActiveRecord::Base.send :include, Bulldog::HasAttachment
ActiveRecord::Base.send :include, Bulldog::Validations
