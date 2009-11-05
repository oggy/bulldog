require 'spec_helper'

describe Vector2 do
  describe "#initialize" do
    def check(object)
      vector = Vector2.new(object)
      vector.x.should == 1
      vector.y.should == -2
    end

    it "should parse strings containing 2 integers" do
      check '1 -2'
      check '+1x-2'
      check '1,-2'
      check '+1-2'
      check '1  -2'
    end

    it "should interpret a 2-element array of integers as x- and y- values" do
      check [1, -2]
    end

    it "should interpret a 2-element array of strings as x- and y- values" do
      check ['1', '-2']
    end
  end
end
