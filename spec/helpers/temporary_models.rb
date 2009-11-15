module TemporaryModels
  def self.included(base)
    base.extend ClassMethods
  end

  #
  # Set up a model class with the given name for all examples in this
  # example group.  +columns+ is a hash from column name to
  # ActiveRecord type (e.g., :string or :integer).
  #
  # The class +name+ may be a String or Symbol.  It can also be a
  # singleton hash mapping the class name to the superclass name.  If
  # the superclass is not ActiveRecord::Base, it is assumed to
  # indicate single table inheritance, and no table will be created.
  #
  def create_model_class(name, columns={}, &class_body)
    if name.is_a?(Hash) && name.size == 1
      class_name, superclass_name = *name.to_a.flatten
    else
      class_name, superclass_name = name, 'ActiveRecord::Base'
    end
    need_table = superclass_name.to_s == 'ActiveRecord::Base'

    table_name = class_name.to_s.underscore.pluralize
    if need_table
      ActiveRecord::Base.connection.create_table(table_name) do |table|
        columns.each do |column_name, column_type|
          table.send column_type, column_name
        end
      end
    end
    klass = Class.new(superclass_name.to_s.constantize, &class_body)
    Object.const_set(class_name, klass)
  end

  #
  # Destroy a model class created with #create_model_class, and drop
  # the created table.  +name+ should be the same as the first
  # argument given on creation.
  #
  def destroy_model_class(name)
    if name.is_a?(Hash) && name.size == 1
      class_name, superclass_name = *name.to_a.flatten
    else
      class_name, superclass_name = name, 'ActiveRecord::Base'
    end
    need_table = superclass_name.to_s == 'ActiveRecord::Base'

    table_name = class_name.to_s.underscore.pluralize
    ActiveRecord::Base.connection.drop_table(table_name) if need_table
    Object.send(:remove_const, class_name)
  end

  #
  # Create a model and table for the duration of the block.  See
  # #create_model_class for the meaning of the arguments.
  #
  def with_model_class(name, columns={})
    create_model_class(name, columns)
    yield
  ensure
    destroy_model_class(name)
  end

  module ClassMethods
    #
    # Create a model and table for the duration of each example in
    # this example group.  See #create_model_class for the meaning of
    # the arguments.
    #
    def use_model_class(name, columns={}, &class_body)
      before{create_model_class(name, columns, &class_body)}
      after{destroy_model_class(name)}
    end
  end
end
