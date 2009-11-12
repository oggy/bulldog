require 'bulldog'

Bulldog.instance_eval do
  self.logger = Rails.logger

  to_interpolate(:rails_root){Rails.root}
  to_interpolate(:rails_env){Rails.env}
  to_interpolate(:public_path){Rails.public_path}
end
