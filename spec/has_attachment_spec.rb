require 'spec_helper'

describe FastAttachments::HasAttachment do
  before do
    Object.const_set(:Thing, Class.new(ActiveRecord::BaseWithoutTable))
    Thing.has_attachment :photo, :format => 'mp4'
  end

  after do
    Object.send(:remove_const, :Thing)
  end

  it "should provide accessors for the attachment" do
    thing = Thing.new
    file = uploaded_file("test.jpg")
    thing.photo = file
    thing.photo.should equal(file)
  end

  it "should provide a query method for the attachment" do
    thing = Thing.new
    file = uploaded_file("test.jpg")
    thing.photo = file
    thing.photo?.should be_true
  end

  describe ".attachments" do
    it "should return the field name with each reflection" do
      Thing.attachments[:photo].name.should == :photo
    end

    it "should return the options with each reflection" do
      Thing.attachments[:photo].options.should == {:format => 'mp4'}
    end
  end
end
