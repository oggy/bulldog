require 'spec_helper'

describe Attribute::Image do
  set_up_model_class :Thing

  before do
    Thing.has_attachment :photo do
      type :image
    end
  end

  it "should be used for image attachments" do
    @thing = Thing.new
    @thing.photo.should be_a(Attribute::Image)
  end
end
