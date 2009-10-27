require 'spec_helper'

describe Interpolation do
  set_up_model_class :Thing do |t|
    t.string :photo_file_name
  end

  def interpolate(template)
    Interpolation.interpolate(template, @thing, :photo, @style)
  end

  describe "when the file name is not being stored" do
    before do
      Thing.has_attachment :photo do
        type :base
        style :small, {}
        store_file_attributes :file_name => nil
      end
      @thing = Thing.new(:photo => uploaded_file('test.jpg', '...'))
      @style = Thing.attachment_reflections[:photo].styles[:small]
    end

    it "should interpolate :rails_root as RAILS_ROOT" do
      with_temporary_constant_value(Object, :RAILS_ROOT, 'RR') do
        interpolate("a/:rails_root/b").should == "a/RR/b"
      end
    end

    it "should interpolate :rails_env as RAILS_ENV" do
      with_temporary_constant_value(Object, :RAILS_ENV, 'RE') do
        interpolate("a/:rails_env/b").should == "a/RE/b"
      end
    end

    it "should interpolate :class as the plural class name" do
      interpolate("a/:class/b").should == "a/things/b"
    end

    it "should interpolate :id as the record ID" do
      @thing.stubs(:id).returns(123)
      interpolate("a/:id/b").should == "a/123/b"
    end

    it "should interpolate :id_partition as the record ID split into 3 3-digit partitions, 0-padded" do
      @thing.stubs(:id).returns(12345)
      interpolate("a/:id_partition/b").should == "a/000/012/345/b"
    end

    it "should interpolate :attachment as the attachment name" do
      interpolate("a/:attachment/b").should == "a/photo/b"
    end

    it "should interpolate :style as the style name" do
      interpolate("a/:style/b").should == "a/small/b"
    end

    it "should raise an error for :basename" do
      lambda{interpolate("a/:basename/b")}.should raise_error(Interpolation::InterpolationError)
    end

    it "should raise an error for :extension" do
      lambda{interpolate("a/:extension/b")}.should raise_error(Interpolation::InterpolationError)
    end

    it "should allow using braces for interpolating between symbol characters" do
      @thing.stubs(:id).returns(5)
      interpolate("a/x:{id}x/b").should == "a/x5x/b"
    end
  end

  describe "when the file name is being stored" do
    before do
      Thing.has_attachment :photo do
        type :base
        style :small, {}
        store_file_attributes :file_name => :photo_file_name
      end

      @thing = Thing.new(:photo => uploaded_file('test.jpg', '...'))
      @style = Thing.attachment_reflections[:photo].styles[:small]
    end

    it "should interpolate :basename as the basename of the uploaded file" do
      interpolate("a/:basename/b").should == "a/test.jpg/b"
    end

    it "should interpolate :extension as the extension of the uploaded file" do
      interpolate("a/:extension/b").should == "a/jpg/b"
    end
  end
end
