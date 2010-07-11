require 'spec_helper'

describe Attachment::Image do
  it_should_behave_like_an_attachment_with_dimensions(
    :type => :image,
    :missing_dimensions => [1, 1],
    :file_40x30 => 'test-40x30.jpg',
    :file_20x10 => 'test-20x10.jpg'
  )

  describe "#process" do
    use_model_class(:Thing, :attachment_file_name => :string)

    before do
      Thing.has_attachment :attachment
      @thing = Thing.new(:attachment => uploaded_file('test.jpg'))
    end

    it "should process with ImageMagick by default" do
      context = nil
      Thing.has_attachment :attachment do
        style :output
        process :on => :event do
          context = self
        end
      end

      @thing.attachment.process(:event)
      context.should be_a(Processor::ImageMagick)
    end
  end

  describe "when an exif:Orientation header is set" do
    use_model_class(:Thing, :attachment_file_name => :string)

    before do
      Thing.has_attachment :attachment
    end

    before do
      @path = temporary_path('test-40x30.jpg')
      @thing = Thing.new
    end

    def run(command)
      output = `#{command} 2>&1`
      $?.success? or
        raise "command failed: #{command}\noutput: #{output}"
    end

    def set_header(path, value)
      tmp = "#{temporary_directory}/exif-tmp.jpg"
      run "exif --create-exif --ifd=EXIF --tag=Orientation --set-value=#{value} --output=#{tmp} #{path}"
      File.rename(tmp, path)
    end

    it "should not swap the dimensions if the value is between 1 and 4" do
      (1..4).each do |value|
        set_header @path, value
        open(@path) do |file|
          @thing.attachment = file
          @thing.attachment.dimensions(:original).should == [40, 30]
        end
      end
    end

    it "should swap the dimensions if the value is between 5 and 8" do
      (5..8).each do |value|
        set_header @path, value
        open(@path) do |file|
          @thing.attachment = file
          @thing.attachment.dimensions(:original).should == [30, 40]
        end
      end
    end
  end
end
