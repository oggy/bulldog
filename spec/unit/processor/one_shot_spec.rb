require 'spec_helper'

describe Processor::OneShot do
  use_model_class(:Thing)

  before do
    Thing.has_attachment :attachment
    @thing = Thing.create(:attachment => test_empty_file)
  end

  def configure(&block)
    Thing.attachment_reflections[:attachment].configure(&block)
  end

  def process(&block)
    configure do
      process(:on => :event, :with => :one_shot, &block)
    end
    @thing.attachment.process(:event)
  end

  describe "any one shot processor", :shared => true do
    it "should run the process block exactly once" do
      num_runs = 0
      process do
        num_runs += 1
      end
      num_runs.should == 1
    end

    it "should provide no styles to the process block" do
      styles = nil
      process do
        styles = self.styles
      end
      styles.should be_empty
    end

    it "should provide no style to the process block" do
      style = nil
      process do
        style = self.style
      end
      style.should be_nil
    end

    it "should provide no output files to the process block" do
      output_file = nil
      process do
        output_file = self.output_file(:one)
      end
      output_file.should be_nil
    end
  end

  describe "when there are no styles defined" do
    it_should_behave_like "any one shot processor"
  end

  describe "when there are multiple styles defined" do
    before do
      configure do
        style :one
        style :two
      end
    end

    it_should_behave_like "any one shot processor"
  end

  describe "A standalone processor" do
    it "should not affect the other processes' styles" do
      style = Style.new(:style)
      styles = StyleSet[style]
      processor = Processor::OneShot.new(mock, styles, mock)
      processor.process{}
      styles.should have(1).style
    end
  end
end
