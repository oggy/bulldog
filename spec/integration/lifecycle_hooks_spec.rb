require 'spec_helper'

describe "Lifecycle hooks" do
  set_up_model_class :Thing do |t|
    t.string :attachment_file_name
    t.integer :value
  end

  before do
    @file = open("#{ROOT}/spec/integration/data/test.jpg")
    Bulldog.default_path = "#{temporary_directory}/attachments/:class/:id.:style.:extension"
  end

  after do
    @file.close
  end

  it "should run before-validation hooks before validating the record" do
    checks = []
    Thing.validates_presence_of :value
    Thing.has_attachment :attachment do
      style :normal
      process :before => :validation do
        checks << record.errors.empty?
      end
    end
    thing = Thing.new(:attachment => @file)
    checks.should == []
    thing.valid?.should be_false
    checks.should == [true]
  end

  it "should run after-validation hooks after validating the record" do
    checks = []
    Thing.validates_presence_of :value
    Thing.has_attachment :attachment do
      style :normal
      process :after => :validation do
        checks << record.errors.empty?
      end
    end
    thing = Thing.new(:attachment => @file)
    checks.should == []
    thing.valid?.should be_false
    checks.should == [false]
  end

  it "should run before-save hooks before saving the record" do
    checks = []
    Thing.has_attachment :attachment do
      style :normal
      process :before => :save do
        checks << record.new_record?
      end
    end
    thing = Thing.new(:attachment => @file)
    checks.should == []
    thing.save.should be_true
    checks.should == [true]
  end

  it "should run after-save hooks after saving the record" do
    checks = []
    Thing.has_attachment :attachment do
      style :normal
      process :after => :save do
        checks << record.new_record?
      end
    end
    thing = Thing.new(:attachment => @file)
    checks.should == []
    thing.save.should be_true
    checks.should == [false]
  end

  it "should run before-create hooks before creating the record" do
    checks = []
    Thing.has_attachment :attachment do
      style :normal
      process :before => :create do
        checks << record.new_record?
      end
    end
    thing = Thing.new(:attachment => @file)
    checks.should == []
    thing.save.should be_true
    checks.should == [true]
  end

  it "should run after-create hooks after creating the record" do
    checks = []
    Thing.has_attachment :attachment do
      style :normal
      process :after => :create do
        checks << record.new_record?
      end
    end
    thing = Thing.new(:attachment => @file)
    checks.should == []
    thing.save.should be_true
    checks.should == [false]
  end

  it "should run before-update hooks before updating the record" do
    checks = []
    Thing.has_attachment :attachment do
      style :normal
      process :before => :update do
        checks << Thing.count(:conditions => {:value => 2})
      end
    end
    Thing.create(:attachment => @file, :value => 1)
    thing = Thing.first
    checks.should == []
    thing.update_attributes(:value => 2).should be_true
    checks.should == [0]
  end

  it "should run after-update hooks after updating the record" do
    checks = []
    Thing.has_attachment :attachment do
      style :normal
      process :after => :update do
        checks << Thing.count(:conditions => {:value => 2})
      end
    end
    Thing.create(:attachment => @file, :value => 1)
    thing = Thing.first
    checks.should == []
    thing.update_attributes(:value => 2).should be_true
    checks.should == [1]
  end

  it "should not run create hooks when updating the record" do
    checks = []
    Thing.has_attachment :attachment do
      style :normal
      process :before => :update do
        checks << [:fail]
      end

      process :after => :update do |thing|
        checks << [:fail]
      end
    end
    Thing.create(:attachment => @file)
    checks.should == []
  end

  it "should not run update hooks when creating the record" do
    checks = []
    Thing.has_attachment :attachment do
      style :normal
      process :before => :create do
        checks << [:fail]
      end

      process :after => :create do
        checks << [:fail]
      end
    end
    thing = Thing.create(:attachment => @file, :value => 1)
    checks = []
    thing.update_attributes(:value => 2)
    checks.should == []
  end

  it "should run callbacks for the given attachment types if given" do
    runs = 0
    Thing.has_attachment :attachment do
      style :normal
      process(:image, :on => :test_event){runs += 1}
    end
    thing = Thing.new(:attachment => @file)
    thing.process_attachment(:attachment, :test_event)
    runs.should == 1
  end

  it "should not run callbacks if the attachment is of the wrong type" do
    runs = 0
    Thing.has_attachment :attachment do
      style :normal
      process(:video, :on => :test_event){runs += 1}
    end
    thing = Thing.new(:attachment => @file)
    thing.process_attachment(:attachment, :test_event)
    runs.should == 0
  end

  it "should allow specifying more than one type" do
    runs = 0
    Thing.has_attachment :attachment do
      style :normal
      process(:image, :video, :on => :test_event){runs += 1}
    end
    thing = Thing.new(:attachment => @file)
    thing.process_attachment(:attachment, :test_event)
    thing.attachment = uploaded_file('test.avi', "RIFF    AVI ")
    thing.process_attachment(:attachment, :test_event)
    runs.should == 2
  end

  it "should run multiple callbacks if given" do
    checks = []
    Thing.has_attachment :attachment do
      style :normal
      process(:on => :test_event){checks << 1}
      process(:on => :test_event){checks << 2}
    end
    thing = Thing.new(:attachment => @file)
    thing.process_attachment(:attachment, :test_event)
    checks.should == [1, 2]
  end
end
