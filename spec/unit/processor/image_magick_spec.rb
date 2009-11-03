require 'spec_helper'

describe Processor::ImageMagick do
  before do
    stub_system_calls
    @styles = StyleSet.new
  end

  use_temporary_attribute_value Processor::ImageMagick, :convert_command, 'CONVERT'
  use_temporary_attribute_value Processor::ImageMagick, :identify_command, 'IDENTIFY'

  def style(name, attributes)
    @styles << Style.new(name, attributes)
  end

  def fake_attachment
    attachment = Object.new
    styles = @styles
    (class << attachment; self; end).class_eval do
      define_method(:path){|style_name| styles[style_name][:path]}
    end
    attachment
  end

  def process(input_path='INPUT.jpg', &block)
    Processor::ImageMagick.new(fake_attachment, @styles, input_path).process(&block)
  end

  describe "#dimensions" do
    it "should yield the dimensions of the input file at that point in the processing pipeline if a block is given" do
      input_path = create_image("#{temporary_directory}/input.jpg", :size => '40x30')
      Kernel.expects(:'`').once.with("CONVERT #{input_path} -format \\%w\\ \\%h -identify /tmp/x.jpg").returns("40 30\n")
      style :x, :path => '/tmp/x.jpg'
      values = []
      process(input_path) do
        dimensions do |*args|
          values << args
        end
      end
      values.should == [[@styles.to_a, 40, 30]]
    end

    it "should yield the dimensions once per branch if called with a block after a branch in the pipeline" do
      input_path = create_image("#{temporary_directory}/input.jpg", :size => '40x30')
      Kernel.expects(:'`').once.with("CONVERT #{input_path} \\( \\+clone -resize 10x10 -format \\%w\\ \\%h -identify -write /tmp/small.jpg \\+delete \\) " +
                                     "-resize 100x100 -format \\%w\\ \\%h -identify /tmp/large.jpg").returns("10 10\n100 100\n")
      style :small, :size => '10x10', :path => '/tmp/small.jpg'
      style :large, :size => '100x100', :path => '/tmp/large.jpg'
      values = []
      process(input_path) do
        resize
        dimensions do |*args|
          values << args
        end
      end
      values.should have(2).sets_of_arguments
      values[0].should == [[@styles[0]], 10, 10]
      values[1].should == [[@styles[1]], 100, 100]
    end
  end

  describe "#process" do
    it "should run convert if no block is given" do
      style :x, :path => '/tmp/x.jpg'
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg /tmp/x.jpg").returns('')
      process
    end

    it "should use the given :quality image setting" do
      style :x, :path => '/tmp/x.jpg', :quality => 50
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -quality 50 /tmp/x.jpg").returns('')
      process{}
    end

    it "should use the :colorspace image setting" do
      style :x, :path => '/tmp/x.jpg', :colorspace => 'rgb'
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -colorspace rgb /tmp/x.jpg").returns('')
      process{}
    end

    it "should log the command run if a logger is set" do
      style :x, :path => '/tmp/x.jpg'
      Kernel.stubs(:'`').returns('')
      Bulldog.logger.expects(:info).with('Running: "CONVERT" "INPUT.jpg" "/tmp/x.jpg"')
      process{}
    end

    it "should not blow up if the logger is set to nil" do
      style :x, :path => '/tmp/x.jpg'
      Kernel.stubs(:'`').returns('')
      Bulldog.logger = nil
      lambda{process{}}.should_not raise_error
    end
  end

  describe "#resize" do
    it "should resize the images to the style's size" do
      style :small, :size => '10x10', :path => '/tmp/small.jpg'
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -resize 10x10 /tmp/small.jpg").returns('')
      process{resize}
    end
  end

  describe "#auto_orient" do
    it "should auto-orient the images" do
      style :small, :path => '/tmp/small.jpg'
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -auto-orient /tmp/small.jpg").returns('')
      process{auto_orient}
    end
  end

  describe "#strip" do
    it "should strip the images" do
      style :small, :size => '10x10', :path => '/tmp/small.jpg'
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -strip /tmp/small.jpg").returns('')
      process{strip}
    end
  end

  describe "#flip" do
    it "should flip the image vertically" do
      style :flipped, :path => '/tmp/flipped.jpg'
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -flip /tmp/flipped.jpg").returns('')
      process{flip}
    end
  end

  describe "#flop" do
    it "should flip the image horizontally" do
      style :flopped, :path => '/tmp/flopped.jpg'
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -flop /tmp/flopped.jpg").returns('')
      process{flop}
    end
  end

  describe "#thumbnail" do
    it "should resize, and crop off the edges" do
      style :small, :size => '10x10', :path => '/tmp/small.jpg'
      Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -resize 10x10\\^ " +
        "-gravity Center -crop 10x10\\+0\\+0 /tmp/small.jpg").returns('')
      process do
        thumbnail
      end
    end
  end

  it "should extract a common prefix if there are multiple styles which start with the same operations" do
    Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -auto-orient " +
      "\\( \\+clone -resize 100x100 -write /tmp/big.jpg \\+delete \\) -resize 40x40 /tmp/small.jpg").returns('')
    style :big, :size => '100x100', :path => '/tmp/big.jpg'
    style :small, :size => '40x40', :path => '/tmp/small.jpg'
    process do
      auto_orient
      resize
    end
  end

  it "should handle a complex tree of arguments optimally" do
    # The tree:
    #   auto-orient
    #     resize 10x20
    #       flip        [:a]
    #       flop        [:b]
    #     flip
    #       strip       [:c]
    #       quality 75  [:d]
    Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -auto-orient " +
      "\\( \\+clone -resize 10x20 \\( \\+clone -flip -write /tmp/a.jpg \\+delete \\) " +
                                              "-flop -write /tmp/b.jpg \\+delete \\) " +
      "-flip \\( \\+clone -flop -write /tmp/c.jpg \\+delete \\) " +
                               "-quality 75 /tmp/d.jpg").returns('')
    style :a, :path => "/tmp/a.jpg", :size => '10x20'
    style :b, :path => "/tmp/b.jpg", :size => '10x20'
    style :c, :path => "/tmp/c.jpg", :size => '30x40'
    style :d, :path => "/tmp/d.jpg", :size => '30x40', :quality => 75
    process do
      auto_orient
      resize if [:a, :b].include?(style.name)
      flip unless style.name == :b
      flop if [:b, :c].include?(style.name)
    end
  end

  it "should allow specifying operations for some styles only by checking #style" do
    Kernel.expects(:'`').once.with("CONVERT INPUT.jpg -auto-orient " +
      "\\( \\+clone -flip -write /tmp/flipped.jpg \\+delete \\) " +
      "-flop /tmp/flopped.jpg").returns('')
    style :flipped, :path => '/tmp/flipped.jpg'
    style :flopped, :path => '/tmp/flopped.jpg'
    process do
      auto_orient
      flip if style.name == :flipped
      flop if style.name == :flopped
    end
  end
end
