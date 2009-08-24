require 'spec_helper'

describe FastAttachments::HasAttachment do
  describe ".has_attachment" do
    setup_model_class :Thing

    it "should provide accessors for the attachment" do
      Thing.has_attachment :photo => :photo
      thing = Thing.new
      file = uploaded_file("test.jpg")
      thing.photo = file
      thing.photo.should equal(file)
    end

    it "should provide a query method for the attachment" do
      Thing.has_attachment :photo => :photo
      thing = Thing.new
      file = uploaded_file("test.jpg")
      thing.photo?.should be_false
      thing.photo = file
      thing.photo?.should be_true
    end

    it "should allow settings styles in a configure block" do
      Thing.has_attachment :photo => :photo do
        style :small, :size => '32x32'
        style :large, :size => '512x512'
      end

      Thing.attachment_reflections[:photo].styles.should == {
        :small => {:size => '32x32'},
        :large => {:size => '512x512'},
      }
    end

    it "should allow setting callbacks in a configure block which can be triggered using #process_attachment" do
      Thing.has_attachment :photo => :photo do
        on(:my_event){|a, b| [a, b]}
      end
      t = Thing.new
      t.process_attachment(:photo, :my_event, 1, 2).should == [1, 2]
    end

    describe ".attachments" do
      it "should allow reflection on the field names" do
        Thing.has_attachment :photo => :photo
        Thing.attachment_reflections[:photo].name.should == :photo
      end
    end

    describe "lifecycle integration" do
      it "should fire :before_assignment before assigning to the association" do
        checks = []
        Thing.has_attachment :photo => :photo do
          before :assignment do |thing, value|
            checks << thing << value << thing.photo
          end
        end
        thing = Thing.new
        io = uploaded_file("test.jpg")
        thing.photo = io
        checks.should == [thing, io, nil]
        thing.photo.should == io
      end

      it "should fire :after_assignment after assigning to the association" do
        checks = []
        Thing.has_attachment :photo => :photo do
          after :assignment do |thing, value|
            checks << thing << value << thing.photo
          end
        end
        thing = Thing.new
        io = uploaded_file("test.jpg")
        thing.photo = io
        checks.should == [thing, io, io]
        thing.photo.should == io
      end

      it "should fire :before_save before saving the record" do
        checks = []
        Thing.has_attachment :photo => :photo do
          before :save do |thing|
            checks << thing << thing.new_record?
          end
        end
        thing = Thing.new
        io = uploaded_file("test.jpg")
        thing.photo = io

        checks.should == []
        thing.save.should be_true
        checks.should == [thing, true]
        thing.photo.should equal(io)
      end

      it "should fire :after_save after saving the record" do
        checks = []
        Thing.has_attachment :photo => :photo do
          after :save do |thing|
            checks << thing << thing.new_record?
          end
        end
        thing = Thing.new
        io = uploaded_file("test.jpg")
        thing.photo = io

        checks.should == []
        thing.save.should be_true
        checks.should == [thing, false]
        thing.photo.should equal(io)
      end
    end
  end
end