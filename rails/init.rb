require 'bulldog'
require File.dirname(__FILE__) + '/rails'

Bulldog::Rails.init("#{Rails.root}/config/bulldog.yml", Rails)
