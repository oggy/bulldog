require 'spec_helper'

describe "Lifecycle hooks" do
  set_up_model_class :Thing do |t|
    t.integer :value
  end

  it "should run before-assignment hooks before assigning to the association" do
    checks = []
    Thing.has_attachment :photo do
      before :assignment do
        checks << value.query
      end
    end
    thing = Thing.new
    checks.should == []
    thing.photo = uploaded_file("test.jpg")
    checks.should == [false]
  end

  it "should run after-assignment hooks after assigning to the association" do
    checks = []
    Thing.has_attachment :photo do
      after :assignment do
        checks << value.query
      end
    end
    thing = Thing.new
    checks.should == []
    thing.photo = uploaded_file("test.jpg")
    checks.should == [true]
  end

  it "should run before-validation hooks before validating the record" do
    checks = []
    Thing.validates_presence_of :value
    Thing.has_attachment :photo do
      before :validation do
        checks << record.errors.empty?
      end
    end
    thing = Thing.new
    checks.should == []
    thing.valid?.should be_false
    checks.should == [true]
  end

  it "should run after-validation hooks after validating the record" do
    checks = []
    Thing.validates_presence_of :value
    Thing.has_attachment :photo do
      after :validation do
        checks << record.errors.empty?
      end
    end
    thing = Thing.new
    checks.should == []
    thing.valid?.should be_false
    checks.should == [false]
  end

  it "should run before-save hooks before saving the record" do
    checks = []
    Thing.has_attachment :photo do
      before :save do
        checks << record.new_record?
      end
    end
    thing = Thing.new
    checks.should == []
    thing.save.should be_true
    checks.should == [true]
  end

  it "should run after-save hooks after saving the record" do
    checks = []
    Thing.has_attachment :photo do
      after :save do
        checks << record.new_record?
      end
    end
    thing = Thing.new
    checks.should == []
    thing.save.should be_true
    checks.should == [false]
  end

  it "should run before-create hooks before creating the record" do
    checks = []
    Thing.has_attachment :photo do
      before :create do
        checks << record.new_record?
      end
    end
    thing = Thing.new
    checks.should == []
    thing.save.should be_true
    checks.should == [true]
  end

  it "should run after-create hooks after creating the record" do
    checks = []
    Thing.has_attachment :photo do
      after :create do
        checks << record.new_record?
      end
    end
    thing = Thing.new
    checks.should == []
    thing.save.should be_true
    checks.should == [false]
  end

  it "should run before-update hooks before updating the record" do
    checks = []
    Thing.has_attachment :photo do
      before :update do
        checks << Thing.count(:conditions => {:value => 2})
      end
    end
    Thing.create(:value => 1)
    thing = Thing.first
    checks.should == []
    thing.update_attributes(:value => 2).should be_true
    checks.should == [0]
  end

  it "should run after-update hooks after updating the record" do
    checks = []
    Thing.has_attachment :photo do
      after :update do
        checks << Thing.count(:conditions => {:value => 2})
      end
    end
    Thing.create(:value => 1)
    thing = Thing.first
    checks.should == []
    thing.update_attributes(:value => 2).should be_true
    checks.should == [1]
  end

  it "should not run create hooks when updating the record" do
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

  it "should not run update hooks when creating the record" do
    checks = []
    Thing.has_attachment :photo do
      before :create do
        checks << [:fail]
      end

      after :create do
        checks << [:fail]
      end
    end
    thing = Thing.create(:value => 1)
    checks = []
    thing.update_attributes(:value => 2)
    checks.should == []
  end

  it "should run multiple callbacks if given" do
    checks = []
    Thing.has_attachment :photo do
      on(:test_event){checks << 1}
      on(:test_event){checks << 2}
    end
    thing = Thing.new
    thing.process_attachment(:photo, :test_event)
    checks.should == [1, 2]
  end
end
