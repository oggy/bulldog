require 'spec_helper'

describe "Processing attachments with ImageMagick" do
  set_up_model_class :Thing

  def identify
    File.dirname(Bulldog::Processor::ImageMagick.convert_command) + '/identify'
  end

  before do
    tmp = temporary_directory
    Thing.has_attachment :photo do
      path "#{tmp}/:id.:style.png"
      style :small, {:size => '10x10'}
      style :large, {:size => '1000x1000'}

      on :resize, :with => :image_magick do
        resize
      end
    end
    @thing = Thing.new
    @thing.stubs(:id).returns(5)

    create_image("#{tmp}/tmp.png", :size => "100x100")
    @file = open("#{tmp}/tmp.png")
  end

  after do
    @file.close
  end

  def path(style)
    "#{temporary_directory}/5.#{style}.png"
  end

  it "should process the attachment when the processor is run" do
    File.exist?(path(:original)).should be_false
    File.exist?(path(:small)).should be_false
    File.exist?(path(:large)).should be_false

    @thing.update_attributes(:photo => @file).should be_true
    @thing.process_attachment(:photo, :resize)

    `"#{identify}" "#{path(:original)}"`.should =~ /100\s*x\s*100/
    $?.should be_success
    `"#{identify}" "#{path(:small)}"`.should =~ /10\s*x\s*10/
    $?.should be_success
    `"#{identify}" "#{path(:large)}"`.should =~ /1000\s*x\s*1000/
    $?.should be_success
  end
end
