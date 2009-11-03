module Bulldog
  class MissingFile
    def initialize(options={})
      @attachment_type = attachment_type
      @file_name = options[:file_name] || 'missing-file'
      @content_type = options[:content_type]
      @path = options[:path] || '/dev/null'
    end

    attr_reader :attachment_type, :file_name, :content_type, :path
  end
end
