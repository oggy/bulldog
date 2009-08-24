require 'spec'
require 'tempfile'
require 'active_record'
require 'action_controller'

require 'init'

module SpecHelper
  def self.included(mod)
    mod.extend ClassMethods
  end

  def uploaded_file(path)
    io = ActionController::UploadedStringIO.new
    io.original_path = path
    io.content_type = Rack::Mime::MIME_TYPES[File.extname(path)]
    io
  end

  module ClassMethods
    def setup_model_class(name, &block)
      block ||= lambda{}
      before do
        ActiveRecord::Base.connection.create_table(name.to_s.underscore.pluralize, &block)
        Object.const_set(name, Class.new(ActiveRecord::Base))
      end

      after do
        Object.send(:remove_const, name)
        ActiveRecord::Base.connection.drop_table(name.to_s.underscore.pluralize)
      end
    end
  end
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.include SpecHelper
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")
