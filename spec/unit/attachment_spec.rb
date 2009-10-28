require 'spec_helper'

describe Attachment do
  set_up_model_class :Thing

  describe ".new" do
    before do
      Thing.has_attachment :photo
      @record = Thing.new
      @name = :photo
    end

    it "should return a None if the value is nil" do
      Attachment.new(@record, @name, nil).should be_a(Attachment::None)
    end

    it "should return an Image if the file is an image file" do
      value = uploaded_file('test.jpg', "\xff\xd8")
      Attachment.new(@record, @name, value).should be_a(Attachment::Image)
    end

    it "should return a Video if the file is a video file" do
      value = uploaded_file('test.avi', 'RIFF    AVI ')
      Attachment.new(@record, @name, value).should be_a(Attachment::Video)
    end

    it "should return a Base otherwise" do
      value = uploaded_file('test.txt', '')
      Attachment.new(@record, @name, value).should be_a(Attachment::Base)
    end
  end
end
