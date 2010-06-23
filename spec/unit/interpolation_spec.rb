require 'spec_helper'

describe Interpolation do
  use_model_class(:Thing, :photo_file_name => :string)

  def interpolate(template, overrides={})
    Interpolation.interpolate(template, @thing, :photo, @style, overrides)
  end

  describe ".to_interpolate" do
    it "should define a custom interpolation token" do
      begin
        Interpolation.to_interpolate(:custom){'VALUE'}
        Thing.has_attachment :attachment do
          style :output
          path "dir/:custom.ext"
        end
        thing = Thing.new
        thing.attachment.interpolate_path(:output).should == "dir/VALUE.ext"
      ensure
        Interpolation.reset
      end
    end
  end

  describe ".reset" do
    it "should remove custom interpolations" do
      Bulldog.to_interpolate(:custom){'VALUE'}
      Bulldog::Interpolation.reset
      Thing.has_attachment :attachment do
        style :output
        path "dir/:custom.ext"
      end
      thing = Thing.new
      lambda{thing.attachment.interpolate_path(:output)}.should raise_error(Interpolation::Error)
    end
  end

  describe ".interpolate" do
    describe "when the file name is not being stored" do
      before do
        Thing.has_attachment :photo do
          style :small
          store_attributes :file_name => nil
        end
        @thing = Thing.new(:photo => test_image_file('test.jpg'))
        @style = Thing.attachment_reflections[:photo].styles[:small]
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

      it "should raise an error for :basename by default" do
        lambda{interpolate("a/:basename/b")}.should raise_error(Interpolation::Error)
      end

      it "should raise an error for :extension by default" do
        lambda{interpolate("a/:extension/b")}.should raise_error(Interpolation::Error)
      end

      it "should allow overriding the basename to use to avoid an error" do
        interpolate("a/:basename/b", :basename => 'BASENAME').should == 'a/BASENAME/b'
      end

      it "should allow overriding the extension to use to avoid an error" do
        interpolate("a/:extension/b", :extension => 'EXT').should == 'a/EXT/b'
      end

      it "should take the extension from the style format, if given" do
        @style[:format] = 'FMT'
        Interpolation.interpolate("a/:extension/b", @thing, :photo, @style).should == 'a/FMT/b'
      end

      it "should take the extension from the overridden basename, if given" do
        interpolate("a/:extension/b", :basename => 'BASENAME.EXT').should == 'a/EXT/b'
      end

      it "should use an extension override over the style format if both are present" do
        @style[:format] = 'FMT'
        interpolate("a/:extension/b", :extension => 'EXT').should == 'a/EXT/b'
      end

      it "should use the style format over the basename override if both are present" do
        @style[:format] = 'FMT'
        interpolate("a/:extension/b", :basename => 'BASENAME.EXT').should == 'a/FMT/b'
      end

      it "should interpolate :root as Bulldog.path_root" do
        Bulldog.path_root = 'TEST'
        interpolate("a/:root/b").should == 'a/TEST/b'
      end

      it "should not modify the hash of overrides, if given" do
        overrides = {:basename => 'BASENAME.EXT'}
        interpolate("a/:extension/b", overrides).should == 'a/EXT/b'
        overrides.should == {:basename => 'BASENAME.EXT'}
      end

      it "should allow using braces for interpolating between symbol characters" do
        @thing.stubs(:id).returns(5)
        interpolate("a/x:{id}x/b").should == "a/x5x/b"
      end

      it "should raise an error for an unrecognized interpolation key" do
        lambda{interpolate(":invalid")}.should raise_error(Interpolation::Error)
      end
    end

    describe "when the file name is being stored" do
      before do
        Thing.has_attachment :photo do
          style :small, {}
          store_attributes :file_name => :photo_file_name
        end

        @thing = Thing.new(:photo => test_image_file('test.jpg'))
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
end
