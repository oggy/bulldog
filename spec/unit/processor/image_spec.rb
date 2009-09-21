require 'spec_helper'

describe Processor::Image do
  before do
    stub_system_calls

    @original_convert_command = Processor::Image.convert_command
    @original_identify_command = Processor::Image.identify_command
    Processor::Image.convert_command = 'CONVERT'
    Processor::Image.identify_command = 'IDENTIFY'

    @styles = StyleSet.new
  end

  after do
    Processor::Image.convert_command = @original_convert_command
    Processor::Image.identify_command = @original_identify_command
  end

  def style(name, attributes)
    @styles << Style.new(name, attributes)
  end

  def process(input_path='INPUT.jpg', &block)
    Processor::Image.new(input_path, @styles).process(nil, nil, &block)
  end

  describe "#dimensions" do
    it "should return the dimensions of the input file" do
      Kernel.expects(:'`').with("IDENTIFY -format \\%w\\ \\%h INPUT.jpg\\[0\\]").returns("40 30\n")
      value = nil
      process do
        value = dimensions
      end
      value.should == [40, 30]
    end

    it "should yield the dimensions of the input file at that point in the processing pipeline if a block is given" do
      input_path = create_image("#{temporary_directory}/input.jpg", :size => '40x30')
      Kernel.expects(:'`').once.with("CONVERT #{input_path} -format \\%w\\ \\%h -identify /tmp/x.jpg").returns("40 30\n")
      style :x, :size => '12x12', :path => '/tmp/x.jpg'
      values = []
      process(input_path) do
        dimensions do |width, height|
          values << [width, height]
        end
      end
      values.should == [[40, 30]]
    end

    it "should support being called with a block after the pipeline branches (yielding the styles along with the values)"
  end

  describe "#convert" do
    describe "when there are no image settings" do
      before do
        style :x, {:path => '/tmp/x.jpg'}
      end

      it "should run convert with the required arguments" do
        Kernel.expects(:'`').once.with("CONVERT INPUT.jpg /tmp/x.jpg").returns('')
        process do
          convert
        end
      end

      it "should log the command run if a logger is set" do
        Kernel.stubs(:'`').returns('')
        Bulldog.logger.expects(:info).with('Running: "CONVERT" "INPUT.jpg" "/tmp/x.jpg"')
        process do
          convert
        end
      end

      it "should not blow up if the logger is set to nil" do
        Kernel.stubs(:'`').returns('')
        Bulldog.logger = nil
        lambda{process{convert}}.should_not raise_error
      end
    end

    it "should apply the :quality style, if given" do
      Bulldog.logger = nil
      style :x, {:path => '/tmp/x.jpg', :quality => 50}
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -quality 50 /tmp/x.jpg").returns('')
      lambda{process{convert}}.should_not raise_error
    end

    it "should apply the colorspace style, if given" do
      Bulldog.logger = nil
      style :x, {:path => '/tmp/x.jpg', :colorspace => 'rgb'}
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -colorspace rgb /tmp/x.jpg").returns('')
      lambda{process{convert}}.should_not raise_error
    end
  end

  describe "#resize" do
    it "should resize the images to the style's size" do
      style :small, {:size => '10x10', :path => '/tmp/small.jpg'}
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -resize 10x10 /tmp/small.jpg").returns('')
      process{resize}
    end
  end

  describe "#auto_orient" do
    it "should auto-orient the images" do
      style :small, {:path => '/tmp/small.jpg'}
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -auto-orient /tmp/small.jpg").returns('')
      process{auto_orient}
    end
  end

  describe "#strip" do
    it "should strip the images" do
      style :small, {:size => '10x10', :path => '/tmp/small.jpg'}
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -strip /tmp/small.jpg").returns('')
      process{strip}
    end
  end

  describe "#thumbnail" do
    it "should resize, and crop off the edges" do
      style :small, {:size => '10x10', :path => '/tmp/small.jpg'}
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -resize 10x10\\^ " +
        "-gravity Center -crop 10x10 /tmp/small.jpg").returns('')
      process do
        thumbnail
      end
    end
  end

  it "should extract a common prefix if there are multiple styles which start with the same operations" do
    Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -auto-orient " +
      "\\( \\+clone -resize 100x100 -write /tmp/big.jpg \\+delete \\) -resize 40x40 /tmp/small.jpg").returns('')
    style :big, {:size => '100x100', :path => '/tmp/big.jpg'}
    style :small, {:size => '40x40', :path => '/tmp/small.jpg'}
    process do
      auto_orient
      resize
    end
  end

  it "should allow specifying operations only for some styles with an :only option" do
    Kernel.expects(:'`').once.with("CONVERT INPUT.jpg \\( \\+clone " +
      "-auto-orient -write /tmp/auto_oriented.jpg \\+delete \\) \\( \\+clone " +
      "-resize 40x40 -write /tmp/small.jpg \\+delete \\) -resize 100x100 /tmp/big.jpg").returns('')
    style :auto_oriented, {:path => '/tmp/auto_oriented.jpg'}
    style :small, {:size => '40x40', :path => '/tmp/small.jpg'}
    style :big, {:size => '100x100', :path => '/tmp/big.jpg'}
    process do
      auto_orient(:only => :auto_oriented)
      resize(:only => [:small, :big])
    end
  end

  it "should allow protecting styles from an operation with an :except option" do
    Kernel.expects(:'`').once.with("CONVERT INPUT.jpg \\( \\+clone -write " +
      "/tmp/unaltered.jpg \\+delete \\) \\( \\+clone -auto-orient -write " +
      "/tmp/unresized.jpg \\+delete \\) -auto-orient -resize 40x40 /tmp/small.jpg").returns('')
    style :unaltered, {:path => '/tmp/unaltered.jpg'}
    style :unresized, {:path => '/tmp/unresized.jpg'}
    style :small, {:size => '40x40', :path => '/tmp/small.jpg'}
    process do
      auto_orient(:except => :unaltered)
      resize(:except => [:unaltered, :unresized])
      convert
    end
  end
end
