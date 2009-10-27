require 'spec_helper'

describe Attachment do
  set_up_model_class :Thing

  describe ".new" do
    before do
      Thing.has_attachment :photo do
        type :image
      end
      @record = Thing.new
      @name = :photo
    end

    it "should return a None if the value is nil" do
      Attachment.new(@record, @name, nil).should be_a(Attachment::None)
    end

    it "should return a Base otherwise" do
      value = uploaded_file('test.txt', '')
      Attachment.new(@record, @name, value).should be_a(Attachment::Base)
    end
  end
end
