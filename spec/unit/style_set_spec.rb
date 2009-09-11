require 'spec_helper'

describe StyleSet do
  describe "#[]" do
    before do
      @one = Style.new(:one, {})
      @two = Style.new(:two, {})
    end

    it "should allow lookup by style name" do
      style_set = StyleSet[@one, @two]
      style_set[:one].should equal(@one)
      style_set[:two].should equal(@two)
    end

    it "should still allow lookup by index" do
      style_set = StyleSet[@one, @two]
      style_set[0].should equal(@one)
      style_set[1].should equal(@two)
    end

    it "should return a special, empty style for :original" do
      style_set = StyleSet[]
      style_set[:original].should == Style.new(:original, {})
    end
  end
end
