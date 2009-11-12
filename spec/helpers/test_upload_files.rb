module TestUploadFiles
  def self.included(mod)
    mod.before{init_test_upload_files}
    mod.after{close_test_upload_files}
  end

  def autoclose(file)
    @files_to_close << file
    file
  end

  def small_uploaded_file(path=unused_temp_path, test_file='test.jpg')
    content = content_for_uploaded_file(test_file)
    io = ActionController::UploadedStringIO.new(content)
    io.original_path = path
    io.content_type = Rack::Mime::MIME_TYPES[File.extname(path)]
    io
  end

  def large_uploaded_file(path=unused_temp_path, test_file='test.jpg')
    content = content_for_uploaded_file(test_file)
    file = ActionController::UploadedTempfile.new(path)
    file.write(content)
    file.rewind
    file.original_path = path
    file.content_type = Rack::Mime::MIME_TYPES[File.extname(path)]
    autoclose(file)
  end

  def uploaded_file_with_content(basename, content)
    io = ActionController::UploadedStringIO.new(content)
    io.original_path = basename
    io.content_type = Rack::Mime::MIME_TYPES[File.extname(basename)]
    io
  end

  def test_path(basename)
    "#{ROOT}/spec/data/#{basename}"
  end

  # For when it doesn't matter if it's small or large.
  alias uploaded_file small_uploaded_file

  def test_image_file(basename='test.jpg')
    path = test_image_path(basename)
    file = open(path)
    autoclose(file)
  end

  def test_image_path(basename='test.jpg')
    test_path(basename)
  end

  def test_video_file(basename='test.mov')
    path = test_video_path(basename)
    file = open(path)
    autoclose(file)
  end

  def test_video_path(basename='test.mov')
    test_path(basename)
  end

  def test_pdf_file(basename='test.pdf')
    path = test_pdf_path(basename)
    file = open(path)
    autoclose(file)
  end

  def test_pdf_path(basename='test.pdf')
    test_path(basename)
  end

  def test_empty_file
    file = open(test_path('empty.txt'))
    autoclose(file)
  end

  private  # ---------------------------------------------------------

  def init_test_upload_files
    @files_to_close = []
  end

  def close_test_upload_files
    @files_to_close.each(&:close)
  end

  def content_for_uploaded_file(test_file)
    path = test_path("test#{File.extname(test_file)}")
    File.read(path)
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
