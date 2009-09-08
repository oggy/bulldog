require 'spec_helper'

describe AttachmentAttribute do
  set_up_model_class :Thing do |t|
    t.string :photo_file_name
  end

  def set_mtime(path, time)
    File.utime(File.atime(path), time, path)
  end

  def write_file(path, contents)
    open(path, 'w'){|f| f.write contents}
  end

  describe "#path" do
    before do
      Thing.has_attachment :photo do
        paths "/:id-:style.jpg"
        style :small, {}
      end
    end

    it "should return the path of the given style, interpolated from the path template" do
      thing = Thing.new(:photo => uploaded_file('test.jpg', ''))
      thing.stubs(:id).returns(5)
      thing.photo.path(:original).should == "/5-original.jpg"
      thing.photo.path(:small).should == "/5-small.jpg"
    end
  end
end
