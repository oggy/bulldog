require 'spec_helper'

describe Attachment::Pdf do
  set_up_model_class :Thing do |t|
    t.string :attachment_file_name
  end

  before do
    Thing.has_attachment :attachment
    @thing = Thing.new(:attachment => test_file)
  end

  def test_file
    path = "#{temporary_directory}/test.pdf"
    FileUtils.cp("#{ROOT}/spec/data/test.pdf", path)
    autoclose open(path)
  end

  def configure(&block)
    Thing.attachment_reflections[:attachment].configure(&block)
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
end
