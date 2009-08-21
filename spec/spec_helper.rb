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
    def setup_model_class(name)
      before do
        Object.const_set(name, Class.new(ActiveRecord::BaseWithoutTable))
      end

      after do
        Object.send(:remove_const, name)
      end
    end
  end
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.include SpecHelper
end

# From the active_record_base_without_table plugin
module ActiveRecord
  class BaseWithoutTable < Base
    self.abstract_class = true

    def create_or_update_without_callbacks
      errors.empty?
    end

    class << self
      def table_exists?
        false
      end

      def columns()
        @columns ||= []
      end

      def column(name, sql_type = nil, default = nil, null = true)
        columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
        reset_column_information
      end

      # Reset everything, except the column information
      def reset_column_information
	columns = @columns
	super
	@columns = columns
      end
    end
  end
end
