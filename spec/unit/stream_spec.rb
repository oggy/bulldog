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

  describe 'all streams', :shared => :true do
    def object(content)
      raise 'example group must define #object'
    end

    def stream(content)
      Stream.new( object(content) )
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
  end

  describe 'for a StringIO' do
    it_should_behave_like 'all streams'

    def object(content)
      StringIO.new(content)
    end
  end

  describe 'for a Tempfile' do
    it_should_behave_like 'all streams'

    def object(content)
      file = Tempfile.new('bulldog-spec')
      file.print(content)
      file
    end
  end

  describe 'for a File opened for reading' do
    it_should_behave_like 'all streams'

    def object(content)
      path = "#{temporary_directory}/file"
      File.open(path, 'w'){|f| f.print content}
      file = File.open(path)
      autoclose_stream(file)
    end
  end

  describe 'for a File opened for writing' do
    it_should_behave_like 'all streams'

    def object(content)
      file = File.open("#{temporary_directory}/file", 'w')
      file.print content
      autoclose_stream(file)
    end
  end

  describe 'for an UnopenedFile' do
    it_should_behave_like 'all streams'

    def object(content)
      path = "#{temporary_directory}/file"
      open(path, 'w'){|f| f.print content}
      UnopenedFile.new(path)
    end
  end

  describe 'for an IO' do
    it_should_behave_like 'all streams'

    def object(content)
      io = IO.popen("echo -n #{content}")
      autoclose_stream(io)
    end
  end
end
