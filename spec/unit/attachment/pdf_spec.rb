require 'spec_helper'

describe Attachment::Pdf do
  it_should_behave_like_an_attachment_with_dimensions(
    :type => :pdf,
    :missing_dimensions => [1, 1],
    :file_40x30 => 'test-40x30.pdf',
    :file_20x10 => 'test-20x10.pdf'
  )

  describe "#process" do
    use_model_class(:Thing, :attachment_file_name => :string)

    before do
      Thing.has_attachment :attachment
      @thing = Thing.new(:attachment => uploaded_file('test.pdf'))
    end

    it "should process with ImageMagick by default" do
      context = nil
      Thing.has_attachment :attachment do
        style :output
        process :on => :event do
          context = self
        end
      end

      @thing.attachment.process(:event)
      context.should be_a(Processor::ImageMagick)
    end
  end
end
