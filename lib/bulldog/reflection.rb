module Bulldog
  class Reflection
    def initialize(model_class, name, &block)
      @model_class = model_class
      @name = name
      configure(&block)
    end

    attr_accessor :model_class, :name, :path_template, :styles, :events, :file_attributes

    def configure(&block)
      configuration = Configuration.new(model_class, name)
      configuration.instance_eval(&block) if block
      [:path_template, :styles, :events, :file_attributes].each do |field|
        send("#{field}=", configuration.send(field))
      end
      model_class.attachment_reflections[name] = self
    end
  end
end
