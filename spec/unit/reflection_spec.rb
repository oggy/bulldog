require 'spec_helper'

describe Reflection do
  set_up_model_class :Thing do |t|
    t.string :photo_file_name
    t.string :photo_content_type

    t.string :custom_file_name
    t.string :custom_content_type
  end

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

      it "should return the URL prefixed with the public path" do
        reflection.path_template.should == ":public_path/configured/url"
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

  describe "#file_missing_callback" do
    it "should return a FileMissingCallback if a file-missing callback was provided" do
      Thing.has_attachment :photo do
        when_file_missing{}
      end
      reflection.file_missing_callback.should be_a(Reflection::FileMissingCallback)
    end

    it "should return nil if no file-missing callback was provided" do
      Thing.has_attachment :photo
      reflection.file_missing_callback.should be_nil
    end
  end

  describe "FileMissingCallback" do
    describe "#call" do
      describe "context" do
        describe "#record" do
          it "should return the record given to #call" do
            record = nil
            Thing.has_attachment :photo do
              when_file_missing{record = self.record}
            end
            dummy_record = Object.new
            reflection.file_missing_callback.call(dummy_record, :name)
            record.should equal(dummy_record)
          end
        end

        describe "#name" do
          it "should return the name given to #call" do
            name = nil
            Thing.has_attachment :photo do
              when_file_missing{name = self.name}
            end
            reflection.file_missing_callback.call(Object.new, :name)
            name.should == :name
          end
        end
      end

      describe "when the callback calls #use_attachment" do
        it "should return an attachment of the corresponding type" do
          Thing.has_attachment :photo do
            when_file_missing do
              use_attachment(:image)
            end
          end
          result = reflection.file_missing_callback.call(Object.new, :name)
          result.should be_a(Attachment::Image)
        end

        it "should return an attachment with a MissingFile value" do
          Thing.has_attachment :photo do
            when_file_missing do
              use_attachment(:image)
            end
          end
          result = reflection.file_missing_callback.call(Object.new, :name)
          result.value.should be_a(MissingFile)
        end

        it "should stop evaluating the block" do
          Thing.has_attachment :photo do
            when_file_missing do
              use_attachment(:image)
              raise
            end
          end
          lambda do
            reflection.file_missing_callback.call(Object.new, :name)
          end.should_not raise_error
        end
      end

      describe "when the callback does not call #use_attachment" do
        it "should return nil" do
          Thing.has_attachment :photo do
            when_file_missing do
              :not_nil
            end
          end
          result = reflection.file_missing_callback.call(Object.new, :name)
          result.should be_nil
        end
      end
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
