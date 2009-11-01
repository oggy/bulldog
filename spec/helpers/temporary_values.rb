module TemporaryValues
  def self.included(mod)
    mod.extend ClassMethods
  end

  #
  # Use +value+ for the value of the constant +mod::name+ for the
  # duration of the block.
  #
  def with_temporary_constant_value(mod, name, value)
    save_and_set_constant(mod, name, value)
    yield
  ensure
    restore_constant(mod, name)
  end

  #
  # Use +value+ for the value of the +name+ attribute of the given
  # +object+ for the duration of the block.
  #
  def with_temporary_attribute_value(object, name, value)
    save_and_set_attribute(object, name, value)
    yield
  ensure
    restore_attribute(object, name)
  end

  module ClassMethods
    #
    # Use +value+ for the value of the constant +mod::name+ for the
    # duration of each example in this example group.
    #
    # If the value should be recalculated for each example, pass a
    # block instead of a value argument.
    #
    def use_temporary_constant_value(mod, name, value=nil, &block)
      before do
        value = block ? instance_eval(&block) : value
        save_and_set_constant(mod, name, value)
      end
      after do
        restore_constant(mod, name)
      end
    end

    #
    # Use +value+ for the value of the +name+ attribute of the given
    # +object+ for the duration of each example in this example group.
    #
    # If the value should be recalculated for each example, pass a
    # block instead of a value argument.
    #
    def use_temporary_attribute_value(object, name, value=nil, &block)
      before do
        value = block ? instance_eval(&block) : value
        save_and_set_attribute(object, name, value)
      end
      after do
        restore_attribute(object, name)
      end
    end
  end

  private  # ---------------------------------------------------------

  UNDEFINED = Object.new

  def original_attribute_values
    @original_attribute_values ||= Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = {}}}
  end

  def save_and_set_attribute(object, name, value)
    original_attribute_values[object.__id__][name] = object.send(name)
    object.send("#{name}=", value)
  end

  def restore_attribute(object, name)
    value = original_attribute_values[object.__id__].delete(name)
    object.send("#{name}=", value)
  end

  def original_constant_values
    @original_constant_values ||= Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = {}}}
  end

  def save_and_set_constant(mod, name, value)
    if mod.const_defined?(name)
      original_constant_values[mod.name][name] = mod.send(:remove_const, name)
    else
      original_constant_values[mod.name][name] = UNDEFINED
    end
    mod.const_set(name, value)
  end

  def restore_constant(mod, name)
    mod.send(:remove_const, name)
    original_value = original_constant_values[mod.name].delete(name)
    unless original_value.equal?(UNDEFINED)
      mod.const_set(name, original_value)
    end
  end
end
