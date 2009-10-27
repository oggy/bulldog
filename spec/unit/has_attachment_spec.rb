require 'spec_helper'

describe HasAttachment do
  set_up_model_class :Thing do |t|
    t.integer :value
  end

  describe ".has_attachment" do
    before do
      Thing.has_attachment :photo do
        type :base
      end
    end

    it "should provide accessors for the attachment" do
      thing = Thing.new
      thing.photo = uploaded_file
      thing.photo.should be_a(Attachment::Base)
    end

    it "should provide a query method for the attachment" do
      thing = Thing.new
      file = uploaded_file
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
    describe "when there is an attachment set" do
      it "should trigger the configured callbacks" do
        args = nil
        Thing.has_attachment :photo do
          type :base
          on(:my_event){|*args|}
        end
        thing = Thing.new(:photo => uploaded_file)
        thing.process_attachment(:photo, :my_event, 1, 2)
        args.should == [1, 2]
      end
    end

    describe "when there is no attachment set" do
      it "should not trigger any callbacks" do
        args = nil
        Thing.has_attachment :photo do
          type :base
          on(:my_event){|*args|}
        end
        thing = Thing.new(:photo => nil)
        thing.process_attachment(:photo, :my_event, 1, 2)
        args.should be_nil
      end
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
      with_temporary_constant_value Processor, :Test, Class.new(Processor::Base) do
        context = nil
        Thing.has_attachment :photo do
          type :base
          on(:my_event, :with => :test){context = self}
        end
        thing = Thing.new(:photo => uploaded_file)
        thing.process_attachment(:photo, :my_event)
        context.should be_a(Processor::Test)
      end
    end

    it "should default to a base processor instance" do
      context = nil
      Thing.has_attachment :photo do
        type :base
        on(:my_event){context = self}
      end
      thing = Thing.new(:photo => uploaded_file)
      thing.process_attachment(:photo, :my_event)
      context.should be_a(Processor::Base)
    end
  end
end
