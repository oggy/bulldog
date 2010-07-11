require 'spec_helper'

describe Stream do
  before do
    @streams = []
  end

  after do
    @streams.each(&:close)
  end

  def autoclose_stream(stream)
    @streams << stream
    stream
  end

  def self.it_should_behave_like_all_streams(options={})
    class_eval do
      def object(content)
        raise 'example group must define #object'
      end

      def stream(content)
        Stream.new( object(content) )
      end
    end

    describe "#size" do
      it "should return the number of bytes in the object" do
        stream = stream('content')
        stream.size.should == 'content'.size
      end
    end

    describe "#path" do
      it "should return the path of a file which contains the contents of the object" do
        stream = stream('content')
        File.read(stream.path).should == 'content'
      end
    end

    describe "#content_type" do
      it "should return the MIME type of the object" do
        stream = stream("\xff\xd8")
        stream.content_type.split(/;/).first.should == 'image/jpeg'
      end
    end

    describe "#write_to" do
      it "should write the contents of the file to the given path" do
        stream = stream('content')
        path = "#{temporary_directory}/written"
        stream.write_to(path)
        File.read(path).should == 'content'
      end
    end

    describe "#file_name" do
      case options[:file_name]
      when :original_path
        it "should return the original path" do
          stream = stream('content')
          stream.target.original_path = 'test.jpg'
          stream.file_name.should == 'test.jpg'
        end
      when :file_name
        it "should return the file name" do
          stream = stream('content')
          stream.target.stubs(:file_name).returns('test.jpg')
          stream.file_name.should == 'test.jpg'
        end
      when :basename
        it "should return the basename of the path" do
          stream = stream('content')
          basename = File.basename(stream.path)
          stream.file_name.should == basename
        end
      else
        it "should return nil" do
          stream = stream('content')
          stream.file_name.should be_nil
        end
      end
    end

    describe "#reload" do
      if options[:reloadable]
        it "should make #size return the new size of the file" do
          stream = stream('content')
          update_target(stream, 'new content')
          stream.reload
          stream.size.should == 'new content'.size
        end

        it "should make #content_type return the new content type of the file" do
          jpg_data = File.read("#{ROOT}/spec/data/test.jpg")
          png_data = File.read("#{ROOT}/spec/data/test.png")
          stream = stream(jpg_data)
          stream.content_type.should =~ %r'\Aimage/jpeg'
          update_target(stream, png_data)
          stream.reload
          stream.content_type.should =~ %r'\Aimage/png'
        end
      else
        it "should not change the result of #size" do
          stream = stream('content')
          stream.reload
          stream.size.should == 'content'.size
        end

        it "should not change the result of #content_type" do
          jpg_data = File.read("#{ROOT}/spec/data/test.jpg")
          stream = stream(jpg_data)
          stream.reload
          stream.content_type.should =~ %r'\Aimage/jpeg'
        end
      end
    end
  end

  describe 'for a small uploaded file' do
    it_should_behave_like_all_streams :file_name => :original_path

    def object(content)
      stringio = StringIO.new(content)
      class << stringio
        attr_accessor :original_path
      end
      stringio
    end
  end

  describe 'for a large uploaded file' do
    it_should_behave_like_all_streams :file_name => :original_path

    def object(content)
      tempfile = Tempfile.new('bulldog-spec')
      tempfile.print(content)
      class << tempfile
        attr_accessor :original_path
      end
      tempfile
    end
  end

  describe Stream::ForStringIO do
    it_should_behave_like_all_streams

    def object(content)
      stringio = StringIO.new(content)
      class << stringio
        attr_accessor :original_path
      end
      stringio
    end
  end

  describe Stream::ForTempfile do
    it_should_behave_like_all_streams

    def object(content)
      file = Tempfile.new('bulldog-spec')
      file.print(content)
      file
    end
  end

  describe "Stream::ForFile (opened for writing)" do
    it_should_behave_like_all_streams :file_name => :basename

    def object(content)
      path = "#{temporary_directory}/file"
      File.open(path, 'w'){|f| f.print content}
      file = File.open(path)
      autoclose_stream(file)
    end

    it "should not do anything if we try to write to the original file" do
      path = "#{temporary_directory}/file"
      open(path, 'w'){|f| f.print 'content'}
      open(path) do |file|
        stream = Stream.new(file)
        lambda{stream.write_to(path)}.should_not raise_error
        File.read(path).should == 'content'
      end
    end
  end

  describe "Stream::ForFile (opened for writing)" do
    it_should_behave_like_all_streams :file_name => :basename

    def object(content)
      file = File.open("#{temporary_directory}/file", 'w')
      file.print content
      autoclose_stream(file)
    end
  end

  describe Stream::ForSavedFile do
    it_should_behave_like_all_streams :file_name => :file_name, :reloadable => true

    def object(content)
      path = "#{temporary_directory}/file"
      open(path, 'w'){|f| f.print content}
      SavedFile.new(path)
    end

    def update_target(stream, content)
      open(stream.target.path, 'w'){|f| f.print content}
    end
  end

  describe Stream::ForMissingFile do
    it_should_behave_like_all_streams :file_name => :file_name

    def object(content)
      path = "#{temporary_directory}/missing-file"
      open(path, 'w'){|f| f.print content}
      MissingFile.new(:path => path)
    end

    describe "for a default MissingFile" do
      before do
        @stream = Stream.new( MissingFile.new )
      end

      it "should have a size of 0" do
        @stream.size.should == 0
      end

      it "should return a string for the path" do
        @stream.path.should be_a(String)
      end

      it "should return a string for the content type" do
        @stream.content_type.should be_a(String)
      end

      it "should default to a file_name that indicates it's a missing file" do
        @stream.file_name.should == 'missing-file'
      end

      it "should write an empty file for #write_to" do
        path = "#{temporary_directory}/missing_file"
        @stream.write_to(path)
        File.read(path).should == ''
      end
    end
  end

  describe Stream::ForIO do
    it_should_behave_like_all_streams

    def object(content)
      readable, writable = IO.pipe
      writable.print content
      writable.close
      autoclose_stream(readable)
    end

    describe "#path" do
      it "should preserve the file extension if an #original_path is available" do
        io = object('content')
        class << io
          def original_path
            'test.xyz'
          end
        end
        stream = Stream.new(io)
        File.extname(stream.path).should == '.xyz'
      end
    end
  end
end
