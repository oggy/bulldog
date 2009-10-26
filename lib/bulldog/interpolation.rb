module Bulldog
  module Interpolation
    InterpolationError = Class.new(Error)

    def self.interpolate(template, attachment, style)
      template.gsub(/:(?:(\w+)|\{(\w+?)\})/) do
        key = $1 || $2
        if @interpolations.key?(key)
          @interpolations[key].call(attachment, style)
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

    define_interpolation :class do |attachment, style|
      attachment.record.class.name.underscore.pluralize
    end

    define_interpolation :id do |attachment, style|
      record = attachment.record
      record.send(record.class.primary_key)
    end

    define_interpolation :id_partition do |attachment, style|
      record = attachment.record
      id = record.send(record.class.primary_key)
      ("%09d" % id).scan(/\d{3}/).join("/")
    end

    define_interpolation :attachment do |attachment, style|
      attachment.name
    end

    define_interpolation :style do |attachment, style|
      style.name
    end

    define_interpolation :basename do |attachment, style|
      attachment.basename or
        raise InterpolationError, ":basename interpolation requires storing the file name - use store_file_attributes to store the file_name"
    end

    define_interpolation :extension do |attachment, style|
      basename = attachment.basename or
        raise InterpolationError, ":basename interpolation requires storing the file name - use store_file_attributes to store the file_name"
      File.extname(basename).sub(/^\./, '')
    end
  end
end
