module Bulldog
  class UnopenedFile
    def initialize(path)
      @path = path
    end

    attr_reader :path

    def size
      File.size(path)
    end
  end
end
