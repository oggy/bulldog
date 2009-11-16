require 'spec_helper'

describe StyleSet do
  before do
    @one = Style.new(:one, {})
    @two = Style.new(:two, {})
    @original = Style.new(:original, {})
  end

  describe "#[]" do
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
      style_set[:original].should == @original
    end
  end

  describe "#clear" do
    before do
      @style_set = StyleSet[@one, @two]
      @style_set.clear
    end

    it "should remove all non-original styles" do
      @style_set[:one].should be_nil
      @style_set[:two].should be_nil
    end

    it "should leave the original style" do
      @style_set[:original].should == @original
    end
  end

  describe "#size" do
    it "should return the number of styles in the set, excluding the :original style" do
      style_set = StyleSet[]
      style_set.size.should == 0
      style_set << Style.new(:style)
      style_set.size.should == 1
    end
  end

  describe "#length" do
    it "should return the number of styles in the set, excluding the :original style" do
      style_set = StyleSet[]
      style_set.length.should == 0
      style_set << Style.new(:style)
      style_set.length.should == 1
    end
  end
end
