require 'bulldog'

ActiveRecord::Base.send :include, Bulldog::HasAttachment
ActiveRecord::Base.send :include, Bulldog::Validations

Bulldog.default_path = ":rails_root/public/assets/:class/:id.:style.:extension"
