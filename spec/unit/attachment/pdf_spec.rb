require 'spec_helper'

describe Attachment::Pdf do
  def test_file
    path = "#{temporary_directory}/test.pdf"
    FileUtils.cp("#{ROOT}/spec/data/test.pdf", path)
    autoclose open(path)
  end

  def configure(&block)
    Thing.attachment_reflections[:attachment].configure(&block)
  end

  describe "when file attributes are not stored" do
    use_model_class(:Thing, :attachment_file_name => :string)

    describe "#dimensions" do
      it "should return 1x1 if the file is missing" do
        Thing.has_attachment :attachment do
          type :pdf
          style :double, :size => '1224x1584'
          style :filled, :size => '500x500', :filled => true
          style :unfilled, :size => '1000x1000'
          default_style :double
        end
        @thing = Thing.new(:attachment => test_file)
        @thing.save.should be_true
        File.unlink(@thing.attachment.path(:original))
        @thing = Thing.find(@thing.id)
        @thing.attachment.is_a?(Attachment::Pdf)  # sanity check
        @thing.attachment.stream.missing?         # sanity check
        @thing.attachment.dimensions(:original).should == [1, 1]
      end
    end
  end

  describe "when file attributes are stored" do
    use_model_class(:Thing,
                    :attachment_file_name => :string,
                    :attachment_width => :integer,
                    :attachment_height => :integer,
                    :attachment_aspect_ratio => :float,
                    :attachment_dimensions => :string)

    before do
      Thing.has_attachment :attachment do
        style :double, :size => '1224x1584'
        style :filled, :size => '500x500', :filled => true
        style :unfilled, :size => '1000x1000'
        default_style :double
      end
      @thing = Thing.new(:attachment => test_file)
    end

    describe "#process" do
      it "should be processed with ImageMagick by default" do
        context = nil
        configure do
          style :output
          process :on => :event do
            context = self
          end
        end

        @thing.attachment.process(:event)
        context.should be_a(Processor::ImageMagick)
      end
    end

    describe "#dimensions" do
      it "should return the width and height of the default style if no style name is given" do
        @thing.attachment.dimensions.should == [1224, 1584]
      end

      it "should return the width and height of the given style" do
        @thing.attachment.dimensions(:original).should == [612, 792]
        @thing.attachment.dimensions(:double).should == [1224, 1584]
      end

      it "should return the calculated width according to style filledness" do
        @thing.attachment.dimensions(:filled).should == [500, 500]
        @thing.attachment.dimensions(:unfilled).should == [773, 1000]
      end

      it "should only invoke identify once"
      it "should log the result"
    end

    describe "#width" do
      it "should return the width of the default style if no style name is given" do
        @thing.attachment.width.should == 1224
      end

      it "should return the width of the given style" do
        @thing.attachment.width(:original).should == 612
        @thing.attachment.width(:double).should == 1224
      end
    end

    describe "#height" do
      it "should return the height of the default style if no style name is given" do
        @thing.attachment.height.should == 1584
      end

      it "should return the height of the given style" do
        @thing.attachment.height(:original).should == 792
        @thing.attachment.height(:double).should == 1584
      end
    end

    describe "#aspect_ratio" do
      it "should return the aspect ratio of the default style if no style name is given" do
        @thing.attachment.aspect_ratio.should be_close(612.0/792, 1e-5)
      end

      it "should return the aspect ratio of the given style" do
        @thing.attachment.aspect_ratio(:original).should be_close(612.0/792, 1e-5)
        @thing.attachment.aspect_ratio(:filled).should be_close(1, 1e-5)
      end
    end

    describe "storable attributes" do
      it "should set the stored attributes on assignment" do
        @thing.attachment_width.should == 612
        @thing.attachment_height.should == 792
        @thing.attachment_aspect_ratio.should be_close(612.0/792, 1e-5)
        @thing.attachment_dimensions.should == '612x792'
      end

      describe "after roundtripping through the database" do
        before do
          @thing.save
          @thing = Thing.find(@thing.id)
        end

        it "should restore the stored attributes" do
          @thing.attachment_width.should == 612
          @thing.attachment_height.should == 792
          @thing.attachment_aspect_ratio.should be_close(612.0/792, 1e-5)
          @thing.attachment_dimensions.should == '612x792'
        end

        it "should recalculate the dimensions correctly" do
          @thing.attachment.dimensions(:filled).should == [500, 500]
          @thing.attachment.dimensions(:unfilled).should == [773, 1000]
        end
      end
    end
  end
end
