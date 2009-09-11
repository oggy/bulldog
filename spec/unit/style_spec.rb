require 'spec_helper'

describe Style do
  describe "#initialize" do
    it "should create a Style with the given name and attributes" do
      style = Style.new(:big, :size => '100x100')
      style.name.should == :big
      style[:size].should == '100x100'
    end
  end

  describe "#==" do
    it "should return true if the names and attributes are both equal" do
      a = Style.new(:big, :size => '100x100')
      b = Style.new(:big, :size => '100x100')
      a.should == b
    end

    it "should return false if the names are not equal" do
      a = Style.new(:big, :size => '100x100')
      b = Style.new(:bad, :size => '100x100')
      a.should_not == b
    end

    it "should return true if the attributes are not equal" do
      a = Style.new(:big, :size => '100x100')
      b = Style.new(:big, :size => '1x1')
      a.should_not == b
    end

    it "should not blow up if the argument is not a Style" do
      a = Style.new(:big, :size => '100x100')
      b = Object.new
      a.should_not == b
    end
  end
end
