require 'spec_helper'

describe Attachment do
  set_up_model_class :Thing

  before do
    Thing.has_attachment :attachment
  end

  describe ".of_type" do
    before do
      @thing = Thing.new
    end

    describe "when the type is nil" do
      before do
        @type = nil
      end

      describe "when the stream is missing" do
        before do
          @stream = Stream.new(MissingFile.new)
        end

        it "should return a None attachment" do
          attachment = Attachment.of_type(@type, @thing, :attachment, @stream)
          attachment.should be_a(Attachment::None)
        end
      end

      describe "when the stream is not missing" do
        before do
          @stream = Stream.new(test_image_file)
        end

        it "should return a Base attachment" do
          attachment = Attachment.of_type(@type, @thing, :attachment, @stream)
          attachment.should be_a(Attachment::Base)
        end
      end
    end

    describe "when the type is not nil" do
      before do
        @type = :video
      end

      it "should return an attachment of the specified type" do
        attachment = Attachment.of_type(@type, @thing, :attachment, @stream)
        attachment.should be_a(Attachment::Video)
      end
    end
  end

  describe ".none" do
    it "should return a None attachment" do
      attachment = Attachment.none(Thing.new, :attachment)
      attachment.should be_a(Attachment::None)
    end
  end
end
