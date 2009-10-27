module TemporaryValues
  def with_temporary_constant_value(mod, constant_name, value)
    defined = mod.const_defined?(constant_name)
    if defined
      original_value = mod.const_get(constant_name)
      mod.send(:remove_const, constant_name)
    end
    mod.const_set(constant_name, value)
    yield
  ensure
    if defined
      mod.const_set(constant_name, original_value)
    else
      mod.send(:remove_const, constant_name)
    end
  end
end
