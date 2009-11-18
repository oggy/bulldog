require 'fileutils'
require 'ostruct'

require 'spec'
require 'rspec_outlines'
require 'mocha'
require 'tempfile'
require 'active_record'
require 'action_controller'

require 'bulldog'
include Bulldog

ROOT = File.dirname( File.dirname(__FILE__) )

require 'helpers/time_travel'
require 'helpers/temporary_models'
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
    mod.use_temporary_attribute_value Bulldog, :default_url_template do
      ":class/:id.:style"
    end
    mod.use_temporary_attribute_value Bulldog, :default_path_template do
      "#{temporary_directory}/attachments/:class/:id.:style"
    end
    mod.use_temporary_attribute_value Bulldog, :logger do
      buffer = StringIO.new
      logger = Logger.new(buffer)
      (class << logger; self; end).send(:define_method, :content) do
        buffer.string
      end
      logger
    end
  end

  #
  # Stub out all system calls.  Pretend they were successful.
  #
  def stub_system_calls
    Kernel.stubs(:system).returns(true)
  end
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.include TimeTravel
  config.include TemporaryModels
  config.include TemporaryValues
  config.include TemporaryDirectory
  config.include TestUploadFiles
  config.include ImageCreation
  config.include Matchers
  config.include SpecHelper
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
