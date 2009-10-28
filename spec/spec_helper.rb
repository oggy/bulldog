require 'fileutils'

require 'spec'
require 'mocha'
require 'tempfile'
require 'active_record'
require 'action_controller'

require 'init'

ROOT = File.dirname( File.dirname(__FILE__) )

require 'helpers/time_travel'
require 'helpers/temporary_values'
require 'helpers/temporary_directory'
require 'helpers/test_upload_files'
require 'helpers/image_creation'
require 'matchers/file_operations'

class Time
  #
  # Return a new Time object with subsecond components dropped.
  #
  # This is useful for testing Time values that have been roundtripped
  # through the database, as not all databases store subsecond
  # precision.
  #
  def drop_subseconds
    self.class.mktime(year, month, day, hour, min, sec)
  end
end

module SpecHelper
  def self.included(mod)
    mod.extend ClassMethods
    mod.before{install_fresh_logger}
    mod.before{set_default_attachment_path}
  end

  #
  # Stub out all system calls.  Pretend they were successful.
  #
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

  def set_default_attachment_path
    Bulldog.default_path = "#{temporary_directory}/attachments/:class/:id.:style"
  end

  module ClassMethods
    #
    # Set up a model class with the given name.  You may pass a block
    # to configure the database table like an ActiveRecord migration.
    #
    def set_up_model_class(name, superclass_name='ActiveRecord::Base', &block)
      need_table = superclass_name == 'ActiveRecord::Base'
      block ||= lambda{}

      before do
        ActiveRecord::Base.connection.create_table(name.to_s.underscore.pluralize, &block) if need_table
        Object.const_set(name, Class.new(superclass_name.to_s.constantize))
      end

      after do
        Object.send(:remove_const, name)
        ActiveRecord::Base.connection.drop_table(name.to_s.underscore.pluralize) if need_table
      end
    end
  end
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.include SpecHelper
  config.include TimeTravel
  config.include TemporaryValues
  config.include TemporaryDirectory
  config.include TestUploadFiles
  config.include ImageCreation
  config.include Matchers
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

# So we don't have to qualify all our classes.
include Bulldog
