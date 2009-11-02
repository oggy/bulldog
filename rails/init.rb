require 'bulldog'

ActiveRecord::Base.send :include, Bulldog::HasAttachment
ActiveRecord::Base.send :include, Bulldog::Validations

Bulldog.default_url_template = "/assets/:class/:id.:style.:extension"
