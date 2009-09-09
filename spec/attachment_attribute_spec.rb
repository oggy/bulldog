require 'spec_helper'

describe AttachmentAttribute do
  set_up_model_class :Thing do |t|
    t.string :photo_file_name
  end

  before do
    tmp = temporary_directory
    Thing.has_attachment :photo do
      paths "#{tmp}/:id.:style.jpg"
      style :small, {}
      store_file_attributes :file_name
    end
    @thing = Thing.new
  end

  def original_path
    "#{temporary_directory}/#{@thing.id}.original.jpg"
  end

  def small_path
    "#{temporary_directory}/#{@thing.id}.small.jpg"
  end

  def set_mtime(path, time)
    File.utime(File.atime(path), time, path)
  end

  def write_file(path, contents)
    open(path, 'w'){|f| f.write contents}
  end

  describe "#path" do
    it "should return the path of the given style, interpolated from the path template" do
      @thing.photo = uploaded_file('test.jpg', '')
      @thing.stubs(:id).returns(5)
      @thing.photo.path(:original).should == original_path
      @thing.photo.path(:small).should == small_path
    end
  end

  describe "before the attribute is assigned" do
    describe "when no attachment is present" do
      it "should make the query method return false" do
        @thing.photo?.should be_false
      end

      it "should return nil for the file attributes" do
        @thing.photo_file_name.should be_nil
      end

      it "should return nil for the path of all styles" do
        @thing.photo.path(:original).should be_nil
        @thing.photo.path(:small).should be_nil
      end
    end

    describe "when an attachment is present" do
      before do
        @thing.update_attributes(:photo => uploaded_file('test.jpg', '...')).should be_true
        @thing = Thing.find(@thing.id)
      end

      it "should make the query method return true" do
        @thing.photo?.should be_true
      end

      it "should return stored file attributes" do
        @thing.photo_file_name.should == "test.jpg"
      end

      it "should return the path to the file for all styles" do
        @thing.photo.path(:original).should == "#{temporary_directory}/#{@thing.id}.original.jpg"
        @thing.photo.path(:small).should == "#{temporary_directory}/#{@thing.id}.small.jpg"
      end
    end
  end

  describe "#set" do
    describe "when no attachment was present" do
      before do
        @thing = Thing.create(:photo => nil)
        @thing.should_not be_new_record
      end

      describe "when a new file is assigned" do
        before do
          @thing.photo = uploaded_file('test2.jpg', '.')
        end

        it "should make the query method return true" do
          @thing.photo?.should be_true
        end

        it "should set the file attributes" do
          @thing.photo_file_name.should == "test2.jpg"
        end

        it "should return the path to the new file for all styles" do
          @thing.photo.path(:original).should == "#{temporary_directory}/#{@thing.id}.original.jpg"
          @thing.photo.path(:small).should == "#{temporary_directory}/#{@thing.id}.small.jpg"
        end
      end

      describe "when nil is assigned" do
        before do
          @thing.photo = nil
        end

        it "should make the query method return false" do
          @thing.photo?.should be_false
        end

        it "should clear the file attributes" do
          @thing.photo_file_name.should be_nil
        end

        it "should return nil for the path of all styles" do
          @thing.photo.path(:original).should be_nil
          @thing.photo.path(:small).should be_nil
        end
      end
    end

    describe "when an attachment was present" do
      before do
        @thing = Thing.create(:photo => uploaded_file('test.jpg', '...'))
        @thing.should_not be_new_record
      end

      describe "when a new file is assigned" do
        before do
          @thing.photo = uploaded_file('test2.jpg', '.')
        end

        it "should make the query method return true" do
          @thing.photo?.should be_true
        end

        it "should set the file attributes" do
          @thing.photo_file_name.should == "test2.jpg"
        end

        it "should return the path to the new file for all styles" do
          @thing.photo.path(:original).should == "#{temporary_directory}/#{@thing.id}.original.jpg"
          @thing.photo.path(:small).should == "#{temporary_directory}/#{@thing.id}.small.jpg"
        end
      end

      describe "when nil is assigned" do
        before do
          @thing.photo = nil
        end

        it "should make the query method return false" do
          @thing.photo?.should be_false
        end

        it "should clear the file attributes" do
          @thing.photo_file_name.should be_nil
        end

        it "should return nil for the path of all styles" do
          @thing.photo.path(:original).should be_nil
          @thing.photo.path(:small).should be_nil
        end
      end
    end
  end
end

describe "AttachmentAttribute which stores file attributes" do
  describe "assigning to an attachment" do
    set_up_model_class :Thing do |t|
      t.string :photo_file_name
      t.string :photo_content_type
      t.integer :photo_file_size
      t.datetime :photo_updated_at
    end

    before do
      Thing.has_attachment :photo
      Thing.attachment_reflections[:photo].stubs(:file_attributes).returns(
        :file_name => :photo_file_name,
        :content_type => :photo_content_type,
        :file_size => :photo_file_size,
        :updated_at => :photo_updated_at
      )
    end

    describe "when the value is a small uploaded file (StringIO)" do
      it "should set the file attributes" do
        file = small_uploaded_file('test.jpg', '...')
        file.should be_a(StringIO)  # sanity check
        thing = Thing.new(:photo => file)
        thing.photo_file_name.should == 'test.jpg'
        thing.photo_content_type.should == 'image/jpeg'
        thing.photo_file_size.should == 3
        thing.photo_updated_at.should == Time.now
      end
    end

    describe "when the value is a large uploaded file (Tempfile)" do
      it "should set the file attributes" do
        file = large_uploaded_file('test.jpg', '...')
        file.should be_a(Tempfile)  # sanity check
        thing = Thing.new(:photo => file)
        thing.photo_file_name.should == 'test.jpg'
        thing.photo_content_type.should == 'image/jpeg'
        thing.photo_file_size.should == 3
        thing.photo_updated_at.should == Time.now
      end
    end

    describe "when the value is nil" do
      it "should clear the file attributes" do
        file = uploaded_file('test.jpg', '...')
        thing = Thing.new(:photo => file)
        # sanity checks
        thing.photo_file_name.should_not be_nil
        thing.photo_content_type.should_not be_nil
        thing.photo_file_size.should_not be_nil
        thing.photo_updated_at.should_not be_nil

        warp_ahead 1.second

        thing.photo = nil
        thing.photo_file_name.should be_nil
        thing.photo_content_type.should be_nil
        thing.photo_file_size.should be_nil
        thing.photo_updated_at.should == Time.now
      end
    end
  end
end
