module TestUploadFiles
  def self.included(mod)
    mod.before{init_test_upload_files}
    mod.after{close_test_upload_files}
  end

  def small_uploaded_file(path, content='')
    io = ActionController::UploadedStringIO.new(content)
    io.original_path = path
    io.content_type = Rack::Mime::MIME_TYPES[File.extname(path)]
    io
  end

  def large_uploaded_file(path, content='')
    file = ActionController::UploadedTempfile.new(path)
    file.write(content)
    file.rewind
    file.original_path = path
    file.content_type = Rack::Mime::MIME_TYPES[File.extname(path)]
    @files_to_close << file
    file
  end

  # For when it doesn't matter if it's small or large.
  alias uploaded_file small_uploaded_file

  private  # ---------------------------------------------------------

  def init_test_upload_files
    @files_to_close = []
  end

  def close_test_upload_files
    @files_to_close.each(&:close)
  end
end