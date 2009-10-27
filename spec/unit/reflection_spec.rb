require 'spec_helper'

describe Reflection do
  set_up_model_class :Thing do |t|
    t.string :photo_file_name
    t.string :photo_content_type
    t.integer :photo_file_size
    t.datetime :photo_updated_at

    t.string :custom_file_name
    t.string :custom_content_type
    t.integer :custom_file_size
    t.datetime :custom_updated_at
  end

  def reflection
    Thing.attachment_reflections[:photo]
  end

  describe "#type" do
    it "should return the configured type" do
      Thing.has_attachment :photo do
        type :image
      end
      reflection.type.should == :image
    end
  end

  describe "#path_template" do
    it "should return the configured path" do
      Thing.has_attachment :photo do
        type :base
        path "/path/to/somewhere"
      end
      reflection.path_template.should == "/path/to/somewhere"
    end

    it "should default to the global setting" do
      Bulldog.default_path = "/test.jpg"
      Thing.has_attachment :photo do
        type :base
      end
      reflection.path_template.should == "/test.jpg"
    end
  end

  describe "#url_template" do
    it "should return the configured URL template" do
      Thing.has_attachment :photo do
        type :base
        url "/path/to/somewhere"
      end
      reflection.url_template.should == "/path/to/somewhere"
    end
  end

  describe "#style" do
    it "should return the set of styles" do
      Thing.has_attachment :photo do
        type :base
        style :small, :size => '32x32'
        style :large, :size => '512x512'
      end
      reflection.styles.should == StyleSet[
        Style.new(:small, {:size => '32x32'}),
        Style.new(:large, {:size => '512x512'}),
      ]
    end
  end

  describe "#default_style" do
    it "should return the configured default_style" do
      Thing.has_attachment :photo do
        type :base
        style :small, :size => '32x32'
        default_style :small
      end
      reflection.default_style.should == :small
    end

    it "should default to :original" do
      Thing.has_attachment :photo do
        type :base
      end
      reflection.default_style.should == :original
    end

    it "should raise an error if the configured default_style is invalid" do
      Thing.has_attachment :photo do
        type :base
        default_style :bad
      end
      lambda{reflection.default_style}.should raise_error(Error)
    end
  end

  describe "#events" do
    it "should return the map of configured events" do
      Thing.has_attachment :photo do
        type :base
        on(:test_event){}
      end
      events = reflection.events[:test_event]
      events.should have(1).event

      event = events.first
      event.should have(2).items
      event[0].should be_a(Class)
      event[1].should be_a(Proc)
    end

    it "should use the specified processor class if given" do
      Processor.const_set(:Test, Class.new(Processor::Base))
      begin
        Thing.has_attachment :photo do
          type :base
          on(:test_event, :with => :test){}
        end
        event = reflection.events[:test_event].first
        event[0].should equal(Processor::Test)
      ensure
        Processor.send(:remove_const, :Test)
      end
    end

    it "should default to using the default processor class" do
      test_processor_class = Class.new(Processor::Base)
      Reflection.any_instance.stubs(:default_processor_class).returns(test_processor_class)
      Thing.has_attachment :photo do
        type :base
        on(:test_event){}
      end
      event = reflection.events[:test_event].first
      event[0].should equal(test_processor_class)
    end
  end

  describe "#file_attributes" do
    it "should return the configured file attributes to store" do
      Thing.has_attachment :photo do
        type :base
        store_file_attributes(
          :file_name => :custom_file_name,
          :content_type => :custom_content_type,
          :file_size => :custom_file_size,
          :updated_at => :custom_updated_at
        )
      end
      reflection.file_attributes.should == {
          :file_name => :custom_file_name,
          :content_type => :custom_content_type,
          :file_size => :custom_file_size,
          :updated_at => :custom_updated_at,
      }
    end

    it "should allow a shortcut if the field names follow convention" do
      Thing.has_attachment :photo do
        type :base
        store_file_attributes :file_name, :content_type, :file_size, :updated_at
      end
      reflection.file_attributes.should == {
        :file_name => :photo_file_name,
        :content_type => :photo_content_type,
        :file_size => :photo_file_size,
        :updated_at => :photo_updated_at,
      }
    end

    it "should store any existing columns that match the default names by default" do
      Thing.has_attachment :photo do
        type :base
      end
      file = uploaded_file('test.jpg', "\xff\xd8")  # jpeg magic number
      thing = Thing.new(:photo => file)
      thing.photo_file_name.should == 'test.jpg'
      thing.photo_content_type.split(/;/).first.should == 'image/jpeg'
      thing.photo_file_size.should == 2
      thing.photo_updated_at.should == Time.now
    end
  end

  describe "#default_processor_class" do
    it "should return a type-specific class if one exists" do
      Thing.has_attachment :photo do
        type :image
      end
      reflection.default_processor_class.should == Processor::Image
    end

    it "should return the base Processor class otherwise" do
      Thing.has_attachment :photo do
        type :psychic_holograph
      end
      reflection.default_processor_class.should == Processor::Base
    end
  end
end
