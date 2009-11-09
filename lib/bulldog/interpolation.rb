module Bulldog
  module Interpolation
    Error = Class.new(Bulldog::Error)

    def self.interpolate(template, record, name, style, overrides={})
      # TODO: would be nice if this wasn't such a special case.
      if overrides[:basename]
        extension = File.extname(overrides[:basename]).sub(/\A./, '')
        overrides[:extension] ||= extension
      end
      template.gsub(/:(?:(\w+)|\{(\w+?)\})/) do
        key = ($1 || $2).to_sym
        if (override = overrides[key])
          override
        elsif @interpolations.key?(key)
          @interpolations[key].call(record, name, style)
        else
          raise Error, "no such interpolation key: #{key}"
        end
      end
    end

    def self.define_interpolation(key, &substitution)
      @interpolations[key] = substitution
    end
    @interpolations = {}

    define_interpolation :rails_root do
      Rails.root
    end

    define_interpolation :rails_env do
      Rails.env
    end

    define_interpolation :public_path do
      Rails.public_path
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
      column_name = reflection.column_name_for_stored_attribute(:file_name) or
        raise Error, ":basename interpolation requires storing the file name - add a column #{name}_file_name or use store_attributes"
      record.send(column_name)
    end

    define_interpolation :extension do |record, name, style|
      reflection = record.attachment_reflection_for(name)
      column_name = reflection.column_name_for_stored_attribute(:file_name) or
        raise Error, ":extension interpolation requires storing the file name - add a column #{name}_file_name or use store_attributes"
      basename = record.send(column_name)
      File.extname(basename).sub(/\A\./, '')
    end
  end
end
