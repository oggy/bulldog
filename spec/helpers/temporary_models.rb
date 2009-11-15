module TemporaryModels
  def self.included(base)
    base.extend ClassMethods
  end

  #
  # Create a table and model for the duration of the given block.
  #
  # +columns+ is a map from column name to type.
  #
  def with_model(model_name, columns={})
    table_name = model_name.to_s.underscore.pluralize
    ActiveRecord::Base.connection.create_table(table_name) do |table|
      columns.each do |column_name, column_type|
        table.send column_type, column_name
      end
    end
    Object.const_set(model_name, Class.new(ActiveRecord::Base))
    yield
  ensure
    ActiveRecord::Base.connection.drop_table(table_name)
    Object.send(:remove_const, model_name)
  end

  module ClassMethods
    #
    # Set up a model class with the given name for all examples in this
    # example group.  You may pass a block to configure the database
    # table like an ActiveRecord migration.
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
