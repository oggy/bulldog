require 'bulldog'

ActiveRecord::Base.send :include, Bulldog::HasAttachment
ActiveRecord::Base.send :include, Bulldog::Validations

Bulldog.default_url = "/assets/:class/:id.:style.:extension"
