module TestUploadFiles
  def self.included(mod)
    mod.before{init_test_upload_files}
    mod.after{close_test_upload_files}
  end

  def autoclose(file)
    @files_to_close << file
    file
  end

  def small_uploaded_file(path=unused_temp_path, content='')
    io = ActionController::UploadedStringIO.new(content)
    io.original_path = path
    io.content_type = Rack::Mime::MIME_TYPES[File.extname(path)]
    io
  end

  def large_uploaded_file(path=unused_temp_path, content='')
    file = ActionController::UploadedTempfile.new(path)
    file.write(content)
    file.rewind
    file.original_path = path
    file.content_type = Rack::Mime::MIME_TYPES[File.extname(path)]
    autoclose(file)
  end

  def test_video_file(base_name)
    file = open("#{ROOT}/spec/data/#{base_name}")
    autoclose(file)
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

  def unused_temp_path
    i = 0
    path = nil
    begin
      path = File.join(temporary_directory, "test-#{i}.jpg")
    end while File.exist?(path)
    path
  end
end
