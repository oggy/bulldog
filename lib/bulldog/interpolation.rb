module Bulldog
  module Interpolation
    InterpolationError = Class.new(Error)

    def self.interpolate(template, record, name, style)
      template.gsub(/:(?:(\w+)|\{(\w+?)\})/) do
        key = $1 || $2
        if @interpolations.key?(key)
          @interpolations[key].call(record, name, style)
        else
          raise InterpolationError, "no such interpolation key: #{key}"
        end
      end
    end

    def self.define_interpolation(key, &substitution)
      @interpolations[key.to_s] = substitution
    end
    @interpolations = {}

    define_interpolation :rails_root do
      RAILS_ROOT
    end

    define_interpolation :rails_env do
      RAILS_ENV
    end

    define_interpolation :class do |record, name, style|
      record.class.name.underscore.pluralize
    end

    define_interpolation :id do |record, name, style|
      record.send(record.class.primary_key)
    end

    define_interpolation :id_partition do |record, name, style|
      id = record.send(record.class.primary_key)
      ("%09d" % id).scan(/\d{3}/).join("/")
    end

    define_interpolation :attachment do |record, name, style|
      name
    end

    define_interpolation :style do |record, name, style|
      style.name
    end

    define_interpolation :basename do |record, name, style|
      reflection = record.attachment_reflection_for(name)
      attribute = reflection.file_attributes[:file_name] or
        raise InterpolationError, ":basename interpolation requires storing the file name - use store_file_attributes to store the file_name"
      record.send(attribute)
    end

    define_interpolation :extension do |record, name, style|
      reflection = record.attachment_reflection_for(name)
      attribute = reflection.file_attributes[:file_name] or
        raise InterpolationError, ":extension interpolation requires storing the file name - use store_file_attributes to store the file_name"
      basename = record.send(attribute)
      File.extname(basename).sub(/^\./, '')
    end
  end
end
