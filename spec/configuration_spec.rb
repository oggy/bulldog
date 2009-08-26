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
      Thing.attachment_attributes[:photo].file_attributes.should == {
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
      Thing.attachment_attributes[:photo].file_attributes.should == {
        :file_name => :photo_file_name,
        :content_type => :photo_content_type,
        :file_size => :photo_file_size,
        :updated_at => :photo_updated_at,
      }
    end

    it "should cause these file attributes to be persisted in the specified columns" do
      Thing.has_attachment :photo do
        store_file_attributes(
          :file_name => :custom_file_name,
          :content_type => :custom_content_type,
          :file_size => :custom_file_size,
          :updated_at => :custom_updated_at
        )
      end
      file = uploaded_file('test.jpg', 'hi')
      thing = Thing.new(:photo => file)
      thing.custom_file_name.should == 'test.jpg'
      thing.custom_content_type.should == 'image/jpeg'
      thing.custom_file_size.should == 2
      thing.custom_updated_at.should == Time.now
    end

    it "should cause these file attributes to be available after reloading the record" do
      Thing.has_attachment :photo do
        store_file_attributes(
          :file_name => :custom_file_name,
          :content_type => :custom_content_type,
          :file_size => :custom_file_size,
          :updated_at => :custom_updated_at
        )
      end
      file = uploaded_file('test.jpg', 'hi')
      thing = Thing.create(:photo => file)
      thing = Thing.find(thing.id)
      thing.custom_file_name.should == 'test.jpg'
      thing.custom_content_type.should == 'image/jpeg'
      thing.custom_file_size.should == 2
      thing.custom_updated_at.should == Time.now
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

    it "should clear the file attributes if nil is assigned" do
      Thing.has_attachment :photo do
        store_file_attributes(
          :file_name => :custom_file_name,
          :content_type => :custom_content_type,
          :file_size => :custom_file_size,
          :updated_at => :custom_updated_at
        )
      end
      Thing.attachment_attributes[:photo].file_attributes.should == {
          :file_name => :custom_file_name,
          :content_type => :custom_content_type,
          :file_size => :custom_file_size,
          :updated_at => :custom_updated_at,
      }
      file = uploaded_file('test.jpg', 'hi')
      thing = Thing.new(:photo => file)

      # sanity checks
      thing.custom_file_name.should == 'test.jpg'
      thing.custom_content_type.should == 'image/jpeg'
      thing.custom_file_size.should == 2
      thing.custom_updated_at.should == Time.now

      thing.photo = nil
      thing.custom_file_name.should be_nil
      thing.custom_content_type.should be_nil
      thing.custom_file_size.should be_nil
      thing.custom_updated_at.should be_nil
    end
  end
end