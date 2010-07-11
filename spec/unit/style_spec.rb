require 'spec_helper'

describe Style do
  describe "#initialize" do
    it "should create a Style with the given name and attributes" do
      style = Style.new(:big, :size => '100x100')
      style.name.should == :big
      style.attributes.should == {:size => '100x100'}
    end
  end

  describe "#[]" do
    it "should return the value of the named attribute" do
      style = Style.new(:big, :size => '100x100')
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

  describe "#inspect" do
    it "should show the name and attributes" do
      style = Style.new(:big, :size => '100x100')
      style.inspect.should == "#<Style :big {:size=>\"100x100\"}>"
    end
  end

  describe "#dimensions" do
    it "should return nil if there is no :size attribute" do
      style = Style.new(:dimensionless)
      style.dimensions.should be_nil
    end

    it "should return the value parsed from the :size attribute" do
      style = Style.new(:dimensionless, :size => '40x30')
      style.dimensions.should == [40, 30]
    end

    describe "when the :size attribute is updated" do
      before do
        @style = Style.new(:dimensionless, :size => '40x30')
      end

      it "should return nil if it was set to nil" do
        @style[:size] = nil
        @style.dimensions.should be_nil
      end

      it "should return the value parsed from the new :size attribute" do
        @style[:size] = '80x60'
        @style.dimensions.should == [80, 60]
      end
    end
  end

  describe "#filled?" do
    it "should return true if the :filled attribute is true" do
      style = Style.new(:filled, :filled => true)
      style.should be_filled
    end

    it "should return false if the :filled attribute is omitted" do
      style = Style.new(:unfilled)
      style.should_not be_filled
    end
  end
end
