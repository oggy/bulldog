module Bulldog
  Error = Class.new(::RuntimeError)
  ConfigurationError = Class.new(Error)
  ProcessingError = Class.new(Error)
end
