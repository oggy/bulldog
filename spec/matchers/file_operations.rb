module Matchers
  #
  # Matches if the Proc object creates the file at the given path.
  # The file also must not exist to begin with.
  #
  def create_file(path)
    CreateFile.new(path)
  end

  #
  # Matches if the Proc deletes the file at the given path.  The file
  # also must exist at the start.
  #
  def delete_file(path)
    DeleteFile.new(path)
  end

  #
  # Matches if the Proc modifies the file at the given path.  Checks
  # by examining the mtime of the file.
  #
  # In order to avoid false-positives, the mtime of the file is set to
  # a temporary value during the block.
  #
  def modify_file(path)
    ModifyFile.new(path)
  end

  class FileOperation
    def initialize(path)
      @path = path
    end

    attr_reader :path
  end

  class CreateFile < FileOperation
    def matches?(proc)
      @file_already_exists = File.exist?(path) and
        return false
      proc.call
      File.exist?(path)
    end

    def does_not_match?(proc)
      @file_already_exists = File.exist?(path) and
        return false
      proc.call
      !File.exist?(path)
    end

    def failure_message_for_should
      if @file_already_exists
        "`#{path}' already exists"
      else
        "expected block to create `#{path}'"
      end
    end

    def failure_message_for_should_not
      if @file_already_exists
        "`#{path}' already exists"
      else
        "expected block to not create `#{path}'"
      end
    end
  end

  class DeleteFile < FileOperation
    def matches?(proc)
      @file_did_not_exist = !File.exist?(path) and
        return false
      proc.call
      !File.exist?(path)
    end

    def does_not_match?(proc)
      @file_did_not_exist = !File.exist?(path) and
        return false
      proc.call
      File.exist?(path)
    end

    def failure_message_for_should
      if @file_did_not_exist
        "`#{path}' does not exist"
      else
        "expected block to delete `#{path}'"
      end
    end

    def failure_message_for_should_not
      if @file_did_not_exist
        "`#{path}' does not exist"
      else
        "expected block to not delete `#{path}'"
      end
    end
  end

  class ModifyFile < FileOperation
    def matches?(proc)
      @file_did_not_exist = !File.exist?(path) and
        return false
      modified?(proc)
    end

    def does_not_match?(proc)
      @file_did_not_exist = !File.exist?(path) and
        return false
      !modified?(proc)
    end

    def failure_message_for_should
      if @file_did_not_exist
        "`#{path}' does not exist"
      else
        "expected block to modify `#{path}'"
      end
    end

    def failure_message_for_should_not
      if @file_did_not_exist
        "`#{path}' does not exist"
      else
        "expected block to not modify `#{path}'"
      end
    end

    private  # -------------------------------------------------------

    def modified?(proc)
      temporarily_setting_mtime_to(1.minute.ago) do
        start_mtime = mtime
        proc.call
        end_mtime = mtime
        start_mtime.to_i != end_mtime.to_i
      end
    end

    def temporarily_setting_mtime_to(time)
      original_time = mtime
      set_mtime_to(time)
      yield
    ensure
      set_mtime_to(original_time)
    end

    def mtime
      File.mtime(path)
    end

    def set_mtime_to(time)
      atime = File.atime(path)
      File.utime(atime, time, path)
      time
    end
  end
end
