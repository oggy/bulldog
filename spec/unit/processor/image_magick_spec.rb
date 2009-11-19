require 'spec_helper'

describe Processor::ImageMagick do
  use_model_class(:Thing, :attachment_file_name => :string)

  before do
    spec = self
    Thing.has_attachment :attachment do
      path "#{spec.temporary_directory}/attachment.:style.:extension"
    end
    thing = Thing.create(:attachment => test_image_file('test.jpg'))
    @thing = Thing.find(thing.id)
  end

  def convert
    Processor::ImageMagick.convert_path
  end

  def original_path
    "#{temporary_directory}/attachment.original.jpg"
  end

  def output_path(style_name=:output)
    "#{temporary_directory}/attachment.#{style_name}.jpg"
  end

  def configure(&block)
    Thing.attachment_reflections[:attachment].configure(&block)
  end

  def style(name, attributes={})
    configure do
      style name, attributes
    end
  end

  def process(*args, &block)
    configure do
      process(:on => :event, :with => :image_magick, &block)
    end
    @thing.attachment.process(:event, *args)
  end

  describe "#dimensions" do
    it "should yield the dimensions of the input file at that point in the processing pipeline if a block is given" do
      style :output
      values = []
      process do
        dimensions do |*args|
          values << args
        end
      end
      styles = Thing.attachment_reflections[:attachment].styles.to_a
      values.should == [[styles, 40, 30]]
    end

    it "should yield the dimensions once per branch if called with a block after a branch in the pipeline" do
      style :small, :size => '4x3'
      style :large, :size => '400x300'
      values = []
      process do
        resize
        dimensions do |*args|
          values << args
        end
      end
      styles = Thing.attachment_reflections[:attachment].styles
      values.should have(2).sets_of_arguments
      values[0].should == [[styles[:small]], 4, 3]
      values[1].should == [[styles[:large]], 400, 300]
    end
  end

  describe "#process" do
    it "should run convert if no block is given" do
      style :output
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", output_path).returns('')
      process
    end

    it "should process the specified set of styles, if given, even those not in the configured style set" do
      style :one
      style :two
      style :three
      styles = []
      configure do
        process(:on => :event, :with => :image_magick, :styles => [:one, :two]) do
          styles << style.name
        end
      end
      @thing.attachment.process(:event, :styles => [:two, :three])
      styles.should == [:two, :three]
    end

    it "should add an error to the record if convert fails" do
      style :output
      Bulldog.stubs(:run).returns(nil)
      process
      @thing.errors.should be_present
    end

    it "should not add an error to the record if convert succeeds" do
      style :output
      Bulldog.stubs(:run).returns('')
      process
      @thing.errors.should_not be_present
    end

    it "should use the given :quality style attribute" do
      style :output, :quality => 50
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-quality', '50', output_path).returns('')
      process
    end

    it "should use the :colorspace style attribute" do
      style :output, :colorspace => 'rgb'
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-colorspace', 'rgb', output_path).returns('')
      process
    end

    it "should use the :format style attribute to set the file extension if it's specified by the :extension interpolation key" do
      style :output, :format => 'png'
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", output_path.sub(/jpg\z/, 'png')).returns('')
      process
    end

    it "should log the command run if a logger is set" do
      style :output
      log_path = "#{temporary_directory}/log"
      open(log_path, 'w') do |file|
        Bulldog.logger = Logger.new(file)
        process
      end
      File.read(log_path).should include("[Bulldog] Running: #{convert}")
    end

    it "should not blow up if the logger is set to nil" do
      style :output
      Bulldog.logger = nil
      lambda{process}.should_not raise_error
    end
  end

  describe "#resize" do
    it "should resize the images to the style's size" do
      style :output, :size => '10x10'
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-resize', '10x10', output_path).returns('')
      process{resize}
    end
  end

  describe "#auto_orient" do
    it "should auto-orient the images" do
      style :output
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-auto-orient', output_path).returns('')
      process{auto_orient}
    end
  end

  describe "#strip" do
    it "should strip the images" do
      style :output, :size => '10x10'
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-strip', output_path).returns('')
      process{strip}
    end
  end

  describe "#flip" do
    it "should flip the image vertically" do
      style :output
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-flip', output_path).returns('')
      process{flip}
    end
  end

  describe "#flop" do
    it "should flip the image horizontally" do
      style :output
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-flop', output_path).returns('')
      process{flop}
    end
  end

  describe "#thumbnail" do
    describe "for filled styles" do
      it "should resize the image to fill the rectangle of the specified size and crop off the edges" do
        style :output, :size => '10x10', :filled => true
        Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-resize', '10x10^',
          '-gravity', 'Center', '-crop', '10x10+0+0', '+repage', output_path).returns('')
        process{thumbnail}
      end
    end

    describe "for unfilled styles" do
      it "should resize the image to fit inside the specified box size" do
        style :output, :size => '10x10'
        Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-resize', '10x10', output_path).returns('')
        process{thumbnail}
      end
    end
  end

  describe "#rotate" do
    it "should rotate the image by the given angle" do
      style :output
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-rotate', '90', output_path).returns('')
      process{rotate 90}
    end

    it "should allow the angle to be given by a string" do
      style :output
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-rotate', '90', output_path).returns('')
      process{rotate '90'}
    end

    it "should not perform any rotation if the given angle is zero" do
      style :output
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", output_path).returns('')
      process{rotate 0}
    end

    it "should not perform any rotation if the given angle is blank" do
      style :output
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", output_path).returns('')
      process{rotate ''}
    end
  end

  describe "#crop" do
    it "should crop the image by the given size and origin, and repage" do
      style :output
      Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-crop', '10x20+30-40', '+repage', output_path).returns('')
      process do
        crop(:size => '10x20', :origin => '30,-40')
      end
    end
  end

  it "should extract a common prefix if there are multiple styles which start with the same operations" do
    Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-auto-orient',
      '(', '+clone', '-resize', '100x100', '-write', output_path(:big), '+delete', ')', '-resize', '40x40', output_path(:small)).returns('')
    style :big, :size => '100x100'
    style :small, :size => '40x40'
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
    Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-auto-orient',
      '(', '+clone', '-resize', '10x20', '(', '+clone', '-flip', '-write', output_path(:a), '+delete', ')',
                                              '-flop', '-write', output_path(:b), '+delete', ')',
      '-flip', '(', '+clone', '-flop', '-write', output_path(:c), '+delete', ')',
                               '-quality', '75', output_path(:d)).returns('')
    style :a, :size => '10x20'
    style :b, :size => '10x20'
    style :c, :size => '30x40'
    style :d, :size => '30x40', :quality => 75
    process do
      auto_orient
      resize if [:a, :b].include?(style.name)
      flip unless style.name == :b
      flop if [:b, :c].include?(style.name)
    end
  end

  it "should allow specifying operations for some styles only by checking #style" do
    Bulldog.expects(:run).once.with(convert, "#{original_path}[0]", '-auto-orient',
      '(', '+clone', '-flip', '-write', output_path(:flipped), '+delete', ')',
      '-flop', output_path(:flopped)).returns('')
    style :flipped, :path => '/tmp/flipped.jpg'
    style :flopped, :path => '/tmp/flopped.jpg'
    process do
      auto_orient
      flip if style.name == :flipped
      flop if style.name == :flopped
    end
  end
end
