module Bulldog
  class UnopenedFile
    def initialize(path, options={})
      @path = path
      @file_name = options[:file_name]
    end

    attr_reader :path

    #
    # The original file name as it was uploaded, if any.
    #
    attr_accessor :file_name

    def size
      File.size(path)
    end
  end
end
