module Bulldog
  module Interpolation
    InterpolationError = Class.new(RuntimeError)

    def self.interpolate(template, attribute, style)
      template.gsub(/:(\w+)/) do
        key = $1
        if @interpolations.key?(key)
          @interpolations[key].call(attribute, style)
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

    define_interpolation :class do |attribute, style|
      attribute.record.class.name.underscore.pluralize
    end

    define_interpolation :id do |attribute, style|
      record = attribute.record
      record.send(record.class.primary_key)
    end

    define_interpolation :id_partition do |attribute, style|
      record = attribute.record
      id = record.send(record.class.primary_key)
      ("%09d" % id).scan(/\d{3}/).join("/")
    end

    define_interpolation :attachment do |attribute, style|
      attribute.name
    end

    define_interpolation :style do |attribute, style|
      style.name
    end

    define_interpolation :basename do |attribute, style|
      attribute.basename or
        raise InterpolationError, ":basename interpolation requires storing the file name - use store_file_attributes to store the file_name"
    end

    define_interpolation :extension do |attribute, style|
      basename = attribute.basename or
        raise InterpolationError, ":basename interpolation requires storing the file name - use store_file_attributes to store the file_name"
      File.extname(basename).sub(/^\./, '')
    end
  end
end
