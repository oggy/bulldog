require 'spec_helper'

describe FastAttachments::HasAttachment do
  describe ".has_attachment" do
    setup_model_class :Thing

    it "should provide accessors for the attachment" do
      Thing.has_attachment :photo
      thing = Thing.new
      file = uploaded_file("test.jpg")
      thing.photo = file
      thing.photo.should equal(file)
    end

    it "should provide a query method for the attachment" do
      Thing.has_attachment :photo
      thing = Thing.new
      file = uploaded_file("test.jpg")
      thing.photo?.should be_false
      thing.photo = file
      thing.photo?.should be_true
    end

    it "should allow settings styles in a configure block" do
      Thing.has_attachment :photo do
        style :small, {:size => '32x32'}
        style :large, {:size => '512x512'}
      end
      Thing.attachment_reflections[:photo].options[:styles].should == {
        :small => {:size => '32x32'},
        :large => {:size => '512x512'},
      }
    end

    describe ".attachments" do
      it "should allow reflection on the field names" do
        Thing.has_attachment :photo
        Thing.attachment_reflections[:photo].name.should == :photo
      end

      it "should allow reflection on the given options" do
        Thing.has_attachment :photo, :format => 'jpg'
        Thing.attachment_reflections[:photo].options.should == {:format => 'jpg'}
      end
    end
  end
end
