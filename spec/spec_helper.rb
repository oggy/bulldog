require 'fileutils'

require 'spec'
require 'mocha'
require 'tempfile'
require 'active_record'
require 'action_controller'

require 'init'

PLUGIN_ROOT = File.dirname( File.dirname(__FILE__) )

require 'helpers/time_travel'
require 'helpers/temporary_directory'
require 'helpers/test_upload_files'

module SpecHelper
  def self.included(mod)
    mod.extend ClassMethods
    mod.before{stub_system_calls}
    mod.before{install_fresh_logger}
  end

  def stub_system_calls
    Kernel.stubs(:system).returns(true)
  end

  def install_fresh_logger
    buffer = StringIO.new
    logger = Logger.new(buffer)
    (class << logger; self; end).send(:define_method, :content) do
      buffer.string
    end
    Bulldog.logger = logger
  end

  module ClassMethods
    #
    # Set up a model class with the given name.  You may pass a block
    # to configure the database table like an ActiveRecord migration.
    #
    def set_up_model_class(name, &block)
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
  config.include TimeTravel
  config.include TemporaryDirectory
  config.include TestUploadFiles
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

# So we don't have to qualify all our classes.
include Bulldog
