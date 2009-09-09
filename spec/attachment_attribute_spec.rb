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
      it "should return false for the query method" do
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

      it "should return true for the query method" do
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
end
