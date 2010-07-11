#
# Temporary file and directory support.
#
module Files
  def self.included(base)
    base.before(:all) { init_temporary_directory }
    base.after(:all) { remove_temporary_directory }
    base.after(:each) { close_open_files }
  end

  #
  # Path of the temporary directory.
  #
  # This is automatically created before any specs are run, and
  # destroyed after the last spec has finished.
  #
  def temporary_directory
    "#{ROOT}/spec/tmp"
  end

  #
  # Return the path to a temporary copy of the file at +path+
  # (relative to spec/data).
  #
  # The copy will be deleted automatically after the last spec has
  # finished.
  #
  # If you want an io object, use #file instead - it will be
  # automatically closed at the end of the spec too.
  #
  def temporary_path(path)
    src = source_path(path)
    dst = temporary_unique_path(path)
    FileUtils.mkdir_p File.dirname(dst)
    FileUtils.cp src, dst
    dst
  end

  #
  # Return an open file for a copy of the file at +path+ (relative to
  # spec/data).
  #
  # The copy will be deleted automatically after the last spec has
  # finished. The file handle will be automatically closed at the end
  # of the spec.
  #
  def file(path)
    tmp_path = temporary_path(path)
    file = open(tmp_path)
    files_to_close << file
    file
  end

  #
  # Like #file, but return an ActionController::UploadedFile.
  #
  # This is the object that Rails provides to a controller when a file
  # is uploaded through a multipart form.
  #
  def uploaded_file(path, content_type=nil)
    io = file(path)
    io.extend(ActionController::UploadedFile)
    io.original_path = File.basename(path)
    io.content_type = content_type || guess_content_type(path)
    io
  end

  #
  # Return the contents of the +path+ relative to spec/data/files.
  #
  def read(path)
    File.read(source_path(path))
  end

  private

  def init_temporary_directory
    remove_temporary_directory
    FileUtils.mkdir_p(temporary_directory)

    # When an attachment is deleted, it deletes empty ancestral
    # directories.  Don't delete past the temporary directory.
    FileUtils.touch "#{temporary_directory}/.do_not_delete"
  end

  def remove_temporary_directory
    FileUtils.rm_rf(temporary_directory)
  end

  def close_open_files
    files_to_close.each{|f| f.close unless f.closed?}
    files_to_close.clear
  end

  def files_to_close
    @files_to_close ||= []
  end

  def source_path(path)
    "#{ROOT}/spec/data/#{path}"
  end

  def temporary_unique_path(path)
    # Find a unique directory name for this process and
    # thread. Maintain the same base name.
    pid_tid = "#{Process.pid}.#{Thread.current.__id__}"
    n = 0
    begin
      dir = "#{temporary_directory}/#{pid_tid}.#{n += 1}"
    end while File.exist?(dir)
    "#{dir}/#{File.basename(path)}"
  end

  def guess_content_type(path)
    case path
    when /\.jpe?g\z/
      'image/jpeg'
    when /\.png\z/
      'image/png'
    when /\.mov\z/
      'video/quicktime'
    when /\.pdf\z/
      'application/pdf'
    when /\.txt\z/
      'text/plain'
    else
      raise ArgumentError, "can't deduce content type for #{path}"
    end
  end
end
