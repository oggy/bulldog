require 'bulldog'

ActiveRecord::Base.send :include, Bulldog::HasAttachment
ActiveRecord::Base.send :include, Bulldog::Validations

if defined?(Rails)
  Bulldog.logger = Rails.logger
end
