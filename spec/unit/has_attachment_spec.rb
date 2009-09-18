require 'spec_helper'

describe HasAttachment do
  set_up_model_class :Thing do |t|
    t.integer :value
  end

  describe ".has_attachment" do
    it "should provide accessors for the attachment" do
      Thing.has_attachment :photo do
        type :base
      end
      thing = Thing.new
      file = uploaded_file("test.jpg")
      thing.photo = file
      thing.photo.should be_a(Attribute)
    end

    it "should provide a query method for the attachment" do
      Thing.has_attachment :photo do
        type :base
      end
      thing = Thing.new
      file = uploaded_file("test.jpg")
      thing.photo?.should be_false
      thing.photo = file
      thing.photo?.should be_true
    end
  end

  describe ".attachment_reflections" do
    it "should allow reflection on the field names" do
      Thing.has_attachment :photo do
        type :base
      end
      Thing.attachment_reflections[:photo].name.should == :photo
    end
  end

  describe "#process_attachment" do
    it "should trigger the named custom callback" do
      args = nil
      Thing.has_attachment :photo do
        type :base
        on(:my_event){|*args|}
      end
      thing = Thing.new
      thing.process_attachment(:photo, :my_event, 1, 2)
      args.should == [1, 2]
    end

    it "should raise an ArgumentError if the attachment name is invalid" do
      args = nil
      Thing.has_attachment :photo do
        type :base
        on(:my_event){|*args|}
      end
      thing = Thing.new
      lambda do
        thing.process_attachment(:fail, :my_event, 1, 2)
      end.should raise_error(ArgumentError)
    end

    it "should evaluate the callback in the context of the specified processor" do
      Processor.const_set(:Test, Class.new(Processor::Base))
      begin
        context = nil
        Thing.has_attachment :photo do
          type :base
          on(:my_event, :with => :test){context = self}
        end
        thing = Thing.new
        thing.process_attachment(:photo, :my_event)
        context.should be_a(Processor::Test)
      ensure
        Processor.send(:remove_const, :Test)
      end
    end

    it "should default to a base processor instance" do
      context = nil
      Thing.has_attachment :photo do
        type :base
        on(:my_event){context = self}
      end
      thing = Thing.new
      thing.process_attachment(:photo, :my_event)
      context.should be_a(Processor::Base)
    end
  end
end
