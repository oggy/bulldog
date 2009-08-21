require 'spec_helper'

describe FastAttachments::HasAttachment do
  before do
    klass = Class.new(ActiveRecord::BaseWithoutTable) do
      has_attachment :photato
    end
    Object.const_set(:Thing, klass)
  end

  after do
    Object.send(:remove_const, :Thing)
  end

  it "should provide accessors for the attachment" do
    thing = Thing.new
    file = uploaded_file("test.jpg")
    thing.photato = file
    thing.photato.should equal(file)
  end

  it "should provide a query method for the attachment" do
    thing = Thing.new
    file = uploaded_file("test.jpg")
    thing.photato = file
    thing.photato?.should be_true
  end
end
