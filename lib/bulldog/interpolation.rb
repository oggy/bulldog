module Bulldog
  module Interpolation
    Error = Class.new(Bulldog::Error)

    def self.interpolate(template, record, name, style, overrides={})
      unless overrides[:extension]
        overrides = overrides.dup
        overrides[:extension] ||= style[:format]
        if overrides[:basename]
          overrides[:extension] ||= File.extname(overrides[:basename]).sub(/\A./, '')
        end
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

    def self.to_interpolate(key, &substitution)
      @interpolations[key] = substitution
    end

    def self.reset
      @interpolations = {}

      to_interpolate :class do |record, name, style|
        record.class.name.underscore.pluralize
      end

      to_interpolate :id do |record, name, style|
        record.send(record.class.primary_key)
      end

      to_interpolate :id_partition do |record, name, style|
        id = record.send(record.class.primary_key)
        ("%09d" % id).scan(/\d{3}/).join("/")
      end

      to_interpolate :attachment do |record, name, style|
        name
      end

      to_interpolate :style do |record, name, style|
        style.name
      end

      to_interpolate :basename do |record, name, style|
        reflection = record.attachment_reflection_for(name)
        column_name = reflection.column_name_for_stored_attribute(:file_name) or
          raise Error, ":basename interpolation requires storing the file name - add a column #{name}_file_name or use store_attributes"
        record.send(column_name)
      end

      to_interpolate :extension do |record, name, style|
        reflection = record.attachment_reflection_for(name)
        column_name = reflection.column_name_for_stored_attribute(:file_name) or
          raise Error, ":extension interpolation requires storing the file name - add a column #{name}_file_name or use store_attributes"
        basename = record.send(column_name) or
          raise Error, ":extension interpolation used when file_name not set - if you need to interpolate the url, pass a :basename override"
        File.extname(basename).sub(/\A\./, '')
      end
    end

    #
    # Reset the list of interpolation definitions.
    #
    reset
  end
end
