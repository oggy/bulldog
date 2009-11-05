require 'spec_helper'

describe Attachment::Image do
  set_up_model_class :Thing do |t|
    t.integer :photo_width
    t.integer :photo_height
    t.float :photo_aspect_ratio
    t.string :photo_dimensions
  end

  before do
    Thing.has_attachment :photo do
      style :double, :size => '80x60'
      style :filled, :size => '60x60', :filled => true
      style :unfilled, :size => '120x120'
      default_style :double
    end
    @thing = Thing.new(:photo => test_file)
  end

  def test_file
    image_path = "#{temporary_directory}/test.jpg"
    create_image(image_path, :size => "40x30")
    SavedFile.new(image_path)
  end

  def run(command)
    `#{command}`
    $?.success? or
      raise "command failed: #{command}"
  end

  describe "#dimensions" do
    it "should return 1x1 if the style is missing" do
      Thing.attachment_reflections[:photo].configure do
        when_file_missing do
          use_attachment(:image)
        end
      end
      @thing.save.should be_true
      File.unlink(@thing.photo.path(:original))
      @thing = Thing.find(@thing.id)
      @thing.photo.dimensions(:original).should == [1, 1]
    end

    it "should return the width and height of the default style if no style name is given" do
      @thing.photo.dimensions.should == [80, 60]
    end

    it "should return the width and height of the given style" do
      @thing.photo.dimensions(:original).should == [40, 30]
      @thing.photo.dimensions(:double).should == [80, 60]
    end

    it "should return the calculated width according to style filledness" do
      @thing.photo.dimensions(:filled).should == [60, 60]
      @thing.photo.dimensions(:unfilled).should == [120, 90]
    end

    it "should honor the exif:Orientation header" do
      path = create_image('test.jpg', :size => '40x30')
      rotated_path = "#{temporary_directory}/rotated-test.jpg"
      run "exif --create-exif --ifd=EXIF --tag=Orientation --set-value=4 --output=#{rotated_path} #{path}"
      open(rotated_path) do |file|
        @thing.photo = file
        @thing.photo.dimensions(:original).should == [30, 40]
      end
    end

    it "should only invoke identify once"
    it "should log the result"
  end

  describe "#width" do
    it "should return the width of the default style if no style name is given" do
      @thing.photo.width.should == 80
    end

    it "should return the width of the given style" do
      @thing.photo.width(:original).should == 40
      @thing.photo.width(:double).should == 80
    end
  end

  describe "#height" do
    it "should return the height of the default style if no style name is given" do
      @thing.photo.height.should == 60
    end

    it "should return the height of the given style" do
      @thing.photo.height(:original).should == 30
      @thing.photo.height(:double).should == 60
    end
  end

  describe "#aspect_ratio" do
    it "should return the aspect ratio of the default style if no style name is given" do
      @thing.photo.aspect_ratio.should be_close(4.0/3, 1e-5)
    end

    it "should return the aspect ratio of the given style" do
      @thing.photo.aspect_ratio(:original).should be_close(4.0/3, 1e-5)
      @thing.photo.aspect_ratio(:filled).should be_close(1, 1e-5)
    end
  end

  describe "storable attributes" do
    it "should set the stored attributes on assignment" do
      @thing.photo_width.should == 40
      @thing.photo_height.should == 30
      @thing.photo_aspect_ratio.should be_close(4.0/3, 1e-5)
      @thing.photo_dimensions.should == '40x30'
    end

    describe "after roundtripping through the database" do
      before do
        @thing.save
        @thing = Thing.find(@thing.id)
      end

      it "should restore the stored attributes" do
        @thing.photo_width.should == 40
        @thing.photo_height.should == 30
        @thing.photo_aspect_ratio.should be_close(4.0/3, 1e-5)
        @thing.photo_dimensions.should == '40x30'
      end

      it "should recalculate the dimensions correctly" do
        @thing.photo.dimensions(:filled).should == [60, 60]
        @thing.photo.dimensions(:unfilled).should == [120, 90]
      end
    end
  end
end
