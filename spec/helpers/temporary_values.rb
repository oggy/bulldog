module TemporaryValues
  def self.included(mod)
    mod.extend ClassMethods
  end

  def with_temporary_constant_value(mod, name, value)
    save_and_set_constant(mod, name, value)
    yield
  ensure
    restore_constant(mod, name)
  end

  module ClassMethods
    #
    # Use the given +value+ for the value of the constant +mod::name+
    # for the duration of each example.
    #
    # If the value should be recalculated for each example, pass a
    # block instead of a value argument.
    #
    def use_temporary_constant_value(mod, name, value=nil, &block)
      before do
        value = block ? block.call : value
        save_and_set_constant(mod, name, value)
      end
      after do
        restore_constant(mod, name)
      end
    end
  end

  private  # ---------------------------------------------------------

  UNDEFINED = Object.new

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
    original_value = original_constant_values[mod.name][name]
    unless original_value.equal?(UNDEFINED)
      mod.const_set(name, original_value)
    end
  end
end
