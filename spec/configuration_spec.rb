require 'spec_helper'

describe Configuration do
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

  describe "#paths" do
    it "should default to the global setting" do
      Bulldog.default_path = "/test.jpg"
      Thing.has_attachment :photo
      Thing.attachment_reflections[:photo].path_template.should == "/test.jpg"
    end

    it "should allow reflection on the paths" do
      Thing.has_attachment :photo do
        paths "/path/to/somewhere"
      end
      Thing.attachment_reflections[:photo].path_template.should == "/path/to/somewhere"
    end
  end

  describe "#style" do
    it "should allow reflection on the styles" do
      Thing.has_attachment :photo do
        style :small, :size => '32x32'
        style :large, :size => '512x512'
      end

      Thing.attachment_reflections[:photo].styles.should == StyleSet[
        Style.new(:small, {:size => '32x32'}),
        Style.new(:large, {:size => '512x512'}),
      ]
    end
  end

  describe "#store_file_attributes" do
    it "should allow reflection on the file attributes" do
      Thing.has_attachment :photo do
        store_file_attributes(
          :file_name => :custom_file_name,
          :content_type => :custom_content_type,
          :file_size => :custom_file_size,
          :updated_at => :custom_updated_at
        )
      end
      Thing.attachment_reflections[:photo].file_attributes.should == {
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
      Thing.attachment_reflections[:photo].file_attributes.should == {
        :file_name => :photo_file_name,
        :content_type => :photo_content_type,
        :file_size => :photo_file_size,
        :updated_at => :photo_updated_at,
      }
    end

    it "should store any existing columns that match the default names by default" do
      Thing.has_attachment :photo
      file = uploaded_file('test.jpg', 'hi')
      thing = Thing.new(:photo => file)
      thing.photo_file_name.should == 'test.jpg'
      thing.photo_content_type.should == 'image/jpeg'
      thing.photo_file_size.should == 2
      thing.photo_updated_at.should == Time.now
    end
  end
end
