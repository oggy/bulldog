require 'spec_helper'

describe HasAttachment do
  set_up_model_class :Thing do |t|
    t.integer :value
  end

  describe ".has_attachment" do
    it "should provide accessors for the attachment" do
      Thing.has_attachment :photo
      thing = Thing.new
      file = uploaded_file("test.jpg")
      thing.photo = file
      thing.photo.should be_a(Attribute)
    end

    it "should provide a query method for the attachment" do
      Thing.has_attachment :photo
      thing = Thing.new
      file = uploaded_file("test.jpg")
      thing.photo?.should be_false
      thing.photo = file
      thing.photo?.should be_true
    end
  end

  describe ".attachment_reflections" do
    it "should allow reflection on the field names" do
      Thing.has_attachment :photo
      Thing.attachment_reflections[:photo].name.should == :photo
    end
  end

  describe "#process_attachment" do
    it "should trigger the named custom callback" do
      args = nil
      Thing.has_attachment :photo do
        on(:my_event){|*args|}
      end
      thing = Thing.new
      thing.process_attachment(:photo, :my_event, 1, 2)
      args.should == [thing, 1, 2]
    end

    it "should raise an ArgumentError if the attachment name is invalid" do
      args = nil
      Thing.has_attachment :photo do
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
        on(:my_event){context = self}
      end
      thing = Thing.new
      thing.process_attachment(:photo, :my_event)
      context.should be_a(Processor::Base)
    end
  end

  describe "lifecycle integration" do
    it "should fire :before_assignment before assigning to the association" do
      checks = []
      Thing.has_attachment :photo do
        before :assignment do |thing, value|
          checks << thing << value << thing.photo?
        end
      end
      thing = Thing.new
      io = uploaded_file("test.jpg")
      thing.photo = io
      checks.should == [thing, io, false]
    end

    it "should fire :after_assignment after assigning to the association" do
      checks = []
      Thing.has_attachment :photo do
        after :assignment do |thing, value|
          checks << thing << value << thing.photo?
        end
      end
      thing = Thing.new
      io = uploaded_file("test.jpg")
      thing.photo = io
      checks.should == [thing, io, true]
    end

    it "should fire :before_validation before validating the record" do
      checks = []
      Thing.validates_presence_of :value
      Thing.has_attachment :photo do
        before :validation do |thing|
          checks << thing << thing.errors.empty?
        end
      end
      thing = Thing.new
      checks.should == []
      thing.valid?.should be_false
      checks.should == [thing, true]
    end

    it "should fire :after_validation after validating the record" do
      checks = []
      Thing.validates_presence_of :value
      Thing.has_attachment :photo do
        after :validation do |thing|
          checks << thing << thing.errors.empty?
        end
      end
      thing = Thing.new
      checks.should == []
      thing.valid?.should be_false
      checks.should == [thing, false]
    end

    it "should fire :before_save before saving the record" do
      checks = []
      Thing.has_attachment :photo do
        before :save do |thing|
          checks << thing << thing.new_record?
        end
      end
      thing = Thing.new
      checks.should == []
      thing.save.should be_true
      checks.should == [thing, true]
    end

    it "should fire :after_save after saving the record" do
      checks = []
      Thing.has_attachment :photo do
        after :save do |thing|
          checks << thing << thing.new_record?
        end
      end
      thing = Thing.new
      checks.should == []
      thing.save.should be_true
      checks.should == [thing, false]
    end

    it "should fire :before_create before creating the record" do
      checks = []
      Thing.has_attachment :photo do
        before :create do |thing|
          checks << thing << thing.new_record?
        end
      end
      thing = Thing.new
      checks.should == []
      thing.save.should be_true
      checks.should == [thing, true]
    end

    it "should fire :after_create after creating the record" do
      checks = []
      Thing.has_attachment :photo do
        after :create do |thing|
          checks << thing << thing.new_record?
        end
      end
      thing = Thing.new
      checks.should == []
      thing.save.should be_true
      checks.should == [thing, false]
    end

    it "should fire :before_update before updating the record" do
      checks = []
      Thing.has_attachment :photo do
        before :update do |thing|
          checks << thing << Thing.count(:conditions => {:value => 2})
        end
      end
      Thing.create(:value => 1)
      thing = Thing.first
      checks.should == []
      thing.update_attributes(:value => 2).should be_true
      checks.should == [thing, 0]
    end

    it "should fire :after_update after updating the record" do
      checks = []
      Thing.has_attachment :photo do
        after :update do |thing|
          checks << thing << Thing.count(:conditions => {:value => 2})
        end
      end
      Thing.create(:value => 1)
      thing = Thing.first
      checks.should == []
      thing.update_attributes(:value => 2).should be_true
      checks.should == [thing, 1]
    end

    it "should not fire :before_create or :after_create when updating the record" do
      checks = []
      Thing.has_attachment :photo do
        before :update do
          checks << [:fail]
        end

        after :update do |thing|
          checks << [:fail]
        end
      end
      Thing.create
      checks.should == []
    end

    it "should not fire :before_update or :after_update when creating the record" do
      checks = []
      Thing.has_attachment :photo do
        before :create do
          checks << [:fail]
        end

        after :create do |thing|
          checks << [:fail]
        end
      end
      thing = Thing.create(:value => 1)
      checks = []
      thing.update_attributes(:value => 2)
      checks.should == []
    end

    describe "with multiple callbacks" do
      it "should support multiple assignment callbacks" do
        checks = []
        Thing.has_attachment :photo do
          before(:assignment){checks << 1}
          before(:assignment){checks << 2}
          after(:assignment){checks << 3}
          after(:assignment){checks << 4}
        end
        checks.should == []
        Thing.new.photo = uploaded_file('test.jpg')
        checks.should == [1, 2, 3, 4]
      end

      it "should support multiple validation callbacks" do
        checks = []
        Thing.has_attachment :photo do
          before(:validation){checks << 1}
          before(:validation){checks << 2}
          after(:validation){checks << 3}
          after(:validation){checks << 4}
        end
        thing = Thing.new
        checks.should == []
        thing.valid?
        checks.should == [1, 2, 3, 4]
      end

      it "should support multiple save callbacks" do
        checks = []
        Thing.has_attachment :photo do
          before(:save){checks << 1}
          before(:save){checks << 2}
          after(:save){checks << 3}
          after(:save){checks << 4}
        end
        thing = Thing.new
        checks.should == []
        thing.save
        checks.should == [1, 2, 3, 4]
      end

      it "should support multiple create callbacks" do
        checks = []
        Thing.has_attachment :photo do
          before(:create){checks << 1}
          before(:create){checks << 2}
          after(:create){checks << 3}
          after(:create){checks << 4}
        end
        checks.should == []
        thing = Thing.create
        checks.should == [1, 2, 3, 4]
      end

      it "should support multiple update callbacks" do
        checks = []
        Thing.has_attachment :photo do
          before(:update){checks << 1}
          before(:update){checks << 2}
          after(:update){checks << 3}
          after(:update){checks << 4}
        end
        thing = Thing.create
        checks = []
        thing.update_attributes(:value => 10)
        checks.should == [1, 2, 3, 4]
      end

      it "should support multiple custom callbacks" do
        checks = []
        Thing.has_attachment :photo do
          on(:background_processing){checks << 1}
          on(:background_processing){checks << 2}
        end
        thing = Thing.create
        checks = []
        thing.process_attachment(:photo, :background_processing)
        checks.should == [1, 2]
      end
    end
  end
end
