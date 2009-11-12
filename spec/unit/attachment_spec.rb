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
      open("#{ROOT}/spec/data/test.jpg") do |file|
        Attachment.new(@record, @name, file).should be_a(Attachment::Image)
      end
    end

    it "should return a Video if the file is a video file" do
      open("#{ROOT}/spec/data/test.mov") do |file|
        Attachment.new(@record, @name, file).should be_a(Attachment::Video)
      end
    end

    it "should return a Pdf if the file is a PDF file" do
      open("#{ROOT}/spec/data/test.pdf") do |file|
        Attachment.new(@record, @name, file).should be_a(Attachment::Pdf)
      end
    end

    it "should return a Base otherwise" do
      open("#{ROOT}/spec/data/empty.txt") do |file|
        Attachment.new(@record, @name, file).should be_a(Attachment::Base)
      end
    end
  end
end
