require 'spec_helper'

describe Attachment::Image do
  set_up_model_class :Thing do |t|
    t.integer :photo_width
    t.integer :photo_height
    t.float :photo_aspect_ratio
    t.string :photo_dimensions
  end

  before do
    Thing.has_attachment :photo
    @thing = Thing.new(:photo => test_file)
  end

  def test_file
    image_path = "#{temporary_directory}/test.jpg"
    create_image(image_path, :size => "40x30")
    UnopenedFile.new(image_path)
  end

  describe "#dimensions" do
    it "should return the width and height of the image" do
      @thing.photo.dimensions.should == [40, 30]
    end

    it "should only invoke identify once"
    it "should log the result"
  end

  describe "#width" do
    it "should return the width of the image" do
      @thing.photo.width.should == 40
    end
  end

  describe "#height" do
    it "should return the height of the image" do
      @thing.photo.height.should == 30
    end
  end

  describe "#aspect_ratio" do
    it "should return the aspect ratio of the image" do
      @thing.photo.aspect_ratio.should be_close(1.33333, 0.00001)
    end
  end

  describe "storable attributes" do
    it "should set the stored attributes on assignment" do
      @thing.photo_width.should == 40
      @thing.photo_height.should == 30
      @thing.photo_aspect_ratio.should be_close(4.0/3, 1e-5)
      @thing.photo_dimensions.should == '40x30'
    end

    it "should successfully roundtrip the stored attributes" do
      @thing.save
      @thing = Thing.find(@thing.id)
      @thing.photo_width.should == 40
      @thing.photo_height.should == 30
      @thing.photo_aspect_ratio.should be_close(4.0/3, 1e-5)
      @thing.photo_dimensions.should == '40x30'
    end
  end
end
