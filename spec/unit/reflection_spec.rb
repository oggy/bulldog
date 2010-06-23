require 'spec_helper'

describe Reflection do
  use_model_class(:Thing,
                  :photo_file_name => :string,
                  :photo_content_type => :string,
                  :custom_file_name => :string,
                  :custom_content_type => :string)

  def reflection
    Thing.attachment_reflections[:photo]
  end

  describe "#configure" do
    it "should append the configuration to any existing configuration" do
      Thing.has_attachment :photo do
        path "/custom/path"
      end
      Thing.attachment_reflections[:photo].configure do
        url "/custom/url"
      end
      reflection.path_template.should == "/custom/path"
      reflection.url_template.should == "/custom/url"
    end

    it "should overwrite any configuration items specified in later blocks" do
      Thing.has_attachment :photo do
        path "/custom/path"
      end
      Thing.has_attachment :photo do
        path "/new/custom/path"
      end
      reflection.path_template.should == "/new/custom/path"
    end
  end

  describe "configuration" do
    # TODO: Restructure the tests so we test by configuration method,
    # not reflection method.
    describe "#process_once" do
      it "should add a process event with a one_shot processor" do
        Thing.has_attachment :photo do
          process_once(:on => :test_event){}
        end
        events = reflection.events[:test_event]
        events.map(&:processor_type).should == [:one_shot]
      end

      it "should raise an ArgumentError if a processor is specified" do
        block_run = false
        spec = self
        Thing.has_attachment :photo do
          block_run = true
          lambda{process_once(:with => :image_magick){}}.should spec.raise_error(ArgumentError)
        end
        block_run.should be_true
      end

      it "should raise an ArgumentError if styles are specified" do
        block_run = false
        spec = self
        Thing.has_attachment :photo do
          block_run = true
          style :one
          lambda{process_once(:styles => [:one]){}}.should spec.raise_error(ArgumentError)
        end
        block_run.should be_true
      end
    end
  end

  describe "#path_template" do
    describe "when a path has been confired for the attachment" do
      before do
        Thing.has_attachment :photo do
          path "/configured/path"
        end
      end

      it "should return the configured path" do
        reflection.path_template.should == "/configured/path"
      end
    end

    describe "when no path has been configured for the attachment, and there is a default path template" do
      use_temporary_attribute_value Bulldog, :default_path_template, "/default/path/template"

      before do
        Thing.has_attachment :photo
      end

      it "should return the default path template" do
        reflection.path_template.should == "/default/path/template"
      end
    end

    describe "when no path has been configured, and there is no default path template" do
      use_temporary_attribute_value Bulldog, :default_path_template, nil

      before do
        Thing.has_attachment :photo do
          url "/configured/url"
        end
      end

      it "should return the URL prefixed with the root" do
        reflection.path_template.should == ":root/configured/url"
      end
    end
  end

  describe "#url_template" do
    describe "when an URL has been configured for the attachment" do
      before do
        Thing.has_attachment :photo do
          url "/path/to/somewhere"
        end
      end

      it "should return the configured URL template" do
        reflection.url_template.should == "/path/to/somewhere"
      end
    end

    describe "when no URL has been configured for the attachment" do
      use_temporary_attribute_value Bulldog, :default_url_template, "/default/url/template"

      before do
        Thing.has_attachment :photo
      end

      it "should return the default URL template" do
        reflection.url_template.should == "/default/url/template"
      end
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

  describe "#detect_type_by" do
    describe "when configured with a symbol" do
      it "should use the named registered type detection proc" do
        args = nil
        Bulldog::Reflection.to_detect_type_by :test_detector do |*args|
          :type
        end
        Thing.has_attachment :photo do
          detect_type_by :test_detector
        end

        thing = Thing.new
        stream = mock
        reflection.detect_attachment_type(thing, stream).should == :type
        args.should == [thing, :photo, stream]
      end
    end

    describe "when configured with a block" do
      it "should call the given block" do
        Thing.has_attachment :photo do
          detect_type_by{:type}
        end
        reflection.detect_attachment_type(Thing.new, mock).should == :type
      end
    end

    describe "when configured with a BoundMethod" do
      it "should call the given method" do
        Thing.stubs(:detect_type).returns(:type)
        Thing.has_attachment :photo do
          detect_type_by Thing.method(:detect_type)
        end
        reflection.detect_attachment_type(Thing.new, mock).should == :type
      end
    end

    describe "when configured with a proc" do
      it "should call the given proc" do
        Thing.has_attachment :photo do
          detect_type_by lambda{:type}
        end
        reflection.detect_attachment_type(Thing.new, mock).should == :type
      end
    end

    describe "when configured with both an argument and a block" do
      it "should raise an ArgumentError" do
        block_run = false
        spec = self
        Thing.has_attachment :photo do
          block_run = true
          lambda do
            detect_type_by(lambda{:type}){:type}
          end.should spec.raise_error(ArgumentError)
        end
        block_run.should be_true
      end
    end

    describe "when configured with #type" do
      it "should return the given type" do
        Thing.has_attachment :photo do
          type :type
        end
        reflection.detect_attachment_type(Thing.new, mock).should == :type
      end
    end
  end

  describe "#stored_attributes" do
    it "should return the configured stored attributes" do
      Thing.has_attachment :photo do
        store_attributes(
          :file_name => :custom_file_name,
          :content_type => :custom_content_type
        )
      end
      reflection.stored_attributes.should == {
          :file_name => :custom_file_name,
          :content_type => :custom_content_type
      }
    end

    it "should allow a shortcut if the field names follow convention" do
      Thing.has_attachment :photo do
        store_attributes :file_name, :content_type
      end
      reflection.stored_attributes.should == {
        :file_name => :photo_file_name,
        :content_type => :photo_content_type,
      }
    end
  end

  describe "#column_name_for_stored_attribute" do
    it "should return nil if the stored attribute has been explicitly mapped to nil" do
      Thing.has_attachment :photo do
        store_attributes :file_name => nil
      end
      reflection.column_name_for_stored_attribute(:file_name).should be_nil
    end

    it "should return the column specified if has been mapped to a column name" do
      Thing.has_attachment :photo do
        store_attributes :file_name => :photo_content_type
      end
      reflection.column_name_for_stored_attribute(:file_name).should == :photo_content_type
    end

    it "should return the default column name if the stored attribute is unspecified, and the column exists" do
      Thing.has_attachment :photo
      reflection.column_name_for_stored_attribute(:file_name).should == :photo_file_name
    end

    it "should return nil if the stored attribute is unspecified, and the column does not exist" do
      Thing.has_attachment :photo
      reflection.column_name_for_stored_attribute(:file_size).should be_nil
    end
  end
end
