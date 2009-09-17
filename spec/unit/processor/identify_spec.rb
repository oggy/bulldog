require 'spec_helper'

describe Processor::Identify do
  before do
    stub_system_calls

    @original_command = Processor::Identify.command
    Processor::Identify.command = 'IDENTIFY'

    @styles = StyleSet.new
  end

  after do
    Processor::Identify.command = @original_command
  end

  def style(name, attributes)
    @styles << Style.new(name, attributes)
  end

  def process(&block)
    Processor::Identify.new('INPUT.JPG', @styles).process(nil, nil, &block)
  end

  describe "#dimensions" do
    it "should return the dimensions of the input file" do
      Kernel.expects(:'`').with("IDENTIFY -format \\%w\\ \\%h INPUT.JPG\\[0\\]").returns('40 30')
      value = nil
      process do
        value = dimensions
      end
      value.should == [40, 30]
    end
  end
end
