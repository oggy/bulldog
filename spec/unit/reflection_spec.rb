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

  describe "#path_template" do
    it "should return the configured path" do
      Thing.has_attachment :photo do
        path "/path/to/somewhere"
      end
      reflection.path_template.should == "/path/to/somewhere"
    end

    it "should default to the global setting" do
      Bulldog.default_path = "/test.jpg"
      Thing.has_attachment :photo
      reflection.path_template.should == "/test.jpg"
    end
  end

  describe "#url_template" do
    it "should return the configured URL template" do
      Thing.has_attachment :photo do
        url "/path/to/somewhere"
      end
      reflection.url_template.should == "/path/to/somewhere"
    end
  end

  describe "#style" do
    it "should return the set of styles" do
      Thing.has_attachment :photo do
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
        style :small, :size => '32x32'
        default_style :small
      end
      reflection.default_style.should == :small
    end

    it "should default to :original" do
      Thing.has_attachment :photo
      reflection.default_style.should == :original
    end

    it "should raise an error if the configured default_style is invalid" do
      Thing.has_attachment :photo do
        default_style :bad
      end
      lambda{reflection.default_style}.should raise_error(Error)
    end
  end

  describe "#events" do
    it "should return the map of configured events" do
      Thing.has_attachment :photo do
        process(:on => :test_event){}
      end
      events = reflection.events[:test_event]
      events.should have(1).event
      events.first.should be_a(Reflection::Event)
    end

    it "should provide access to the processor type of each event" do
      Thing.has_attachment :photo do
        process(:on => :test_event, :with => :test){}
      end
      event = reflection.events[:test_event].first
      event.processor_type.should == :test
    end

    it "should have nil as the processor type if the default processor type is to be used" do
      Thing.has_attachment :photo do
        process(:on => :test_event){}
      end
      event = reflection.events[:test_event].first
      event.processor_type.should be_nil
    end

    it "should have the configured styles" do
      Thing.has_attachment :photo do
        style :small, :size => '10x10'
        style :large, :size => '1000x1000'
        process(:on => :test_event, :styles => [:small]){}
      end
      event = reflection.events[:test_event].first
      event.styles.should == [:small]
    end

    it "should provide access to the callback of each event" do
      Thing.has_attachment :photo do
        process(:on => :test_event){}
      end
      event = reflection.events[:test_event].first
      event.callback.should be_a(Proc)
    end
  end

  describe "#file_attributes" do
    it "should return the configured file attributes to store" do
      Thing.has_attachment :photo do
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
      Thing.has_attachment :photo
      file = uploaded_file('test.jpg', "\xff\xd8")  # jpeg magic number
      thing = Thing.new(:photo => file)
      thing.photo_file_name.should == 'test.jpg'
      thing.photo_content_type.split(/;/).first.should == 'image/jpeg'
      thing.photo_file_size.should == 2
      thing.photo_updated_at.should == Time.now
    end
  end
end
