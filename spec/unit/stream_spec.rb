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
          stream.target.file_name = 'test.jpg'
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
      stringio = StringIO.new(content)
      class << stringio
        attr_accessor :original_path
      end
      stringio
    end
  end

  describe 'for a StringIO' do
    it_should_behave_like_all_streams

    def object(content)
      tempfile = Tempfile.new('bulldog-spec')
      tempfile.print(content)
      class << tempfile
        attr_accessor :original_path
      end
      tempfile
    end
  end

  describe 'for a Tempfile' do
    it_should_behave_like_all_streams

    def object(content)
      file = Tempfile.new('bulldog-spec')
      file.print(content)
      file
    end
  end

  describe 'for a File opened for reading' do
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

  describe 'for a File opened for writing' do
    it_should_behave_like_all_streams :file_name => :basename

    def object(content)
      file = File.open("#{temporary_directory}/file", 'w')
      file.print content
      autoclose_stream(file)
    end
  end

  describe 'for an SavedFile' do
    it_should_behave_like_all_streams :file_name => :file_name

    def object(content)
      path = "#{temporary_directory}/file"
      open(path, 'w'){|f| f.print content}
      SavedFile.new(path)
    end
  end

  describe 'for an IO' do
    it_should_behave_like_all_streams

    def object(content)
      io = IO.popen("echo -n #{content}")
      autoclose_stream(io)
    end
  end
end
